<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
<title>채팅방: ${chatRoom.name}</title>
<style>
#chatContent {
	border: 1px solid #ddd;
	height: 300px;
	overflow-y: scroll;
	margin-bottom: 10px;
}

#userList {
	list-style-type: none;
	padding: 0;
}

#userList li {
	margin: 5px 0;
}

.whisper {
	color: grey;
}

.admin {
	color: red;
}
</style>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
	<div>
		<h2>채팅방: ${chatRoom.name}</h2>
		<p>방장: ${chatRoom.host}</p>
		<div id="chatContent">
			<!-- 채팅 내용 출력 -->
		</div>
		<form id="chatForm">
			<input type="text" id="message" name="message"> <input
				type="hidden" id="sender" name="sender"
				value="${sessionScope.memberId}"> <input type="hidden"
				id="recipient" name="recipient" value="${sessionScope.username}">
			<input type="hidden" id="chatRoomId" name="chatRoomId"
				value="${chatRoom.id}">
			<button type="submit">전송</button>
		</form>
		<button id="exitButton">나가기</button>

		<h3>접속자 목록</h3>
		<ul id="userList">
			<!-- 접속자 목록 출력 -->
		</ul>
	</div>
	<script>
    	const sender = $('#sender').val();
    	const chatRoomHost = '${chatRoom.host}';
    	const chatRoomId = '${chatRoom.id}';
    	console.log('chatRoomId:', chatRoomId);
    	let isWhisperMode = false; //귓속말모드|일반모드
    	let whisperRecipient = null;
    	
    	// 채팅방 나가기
    	 document.getElementById('exitButton').addEventListener('click', function() {
             if (confirm('채팅방이 종료됩니다. 나가시겠습니까?')) {
                 $.ajax({
                     url: '${pageContext.request.contextPath}/chat/leaveRoom',
                     type: 'POST',
                     data: JSON.stringify({
                         chatRoomId: chatRoomId,
                         memberId: sender
                     }),
                     contentType: 'application/json',
                     success: function() {
                         window.location.href = '${pageContext.request.contextPath}/chat/chatList';
                     }
                 });
             }
         });
    	 
     	// 브라우저에서 뒤로가기 채팅방 나가기
     	window.addEventListener('beforeunload', function(event) {
            const payload = JSON.stringify({
                chatRoomId: chatRoomId,
                memberId: sender
            });
            navigator.sendBeacon('${pageContext.request.contextPath}/chat/leaveRoom', payload);
        });
    	 
        // 귓속말
        $(document).on('click', '.whisperButton', function() {
            const username = $(this).parent().data('username');
            whisperRecipient = username;
            isWhisperMode = true;
            alert(username + "님에게 귓속말 모드가 활성화되었습니다. 이제 메시지를 입력하세요.");
        });
        
        // 채팅메시지 전송
        document.getElementById('chatForm').addEventListener('submit', function(event) {
            event.preventDefault();
            const message = document.getElementById('message').value.trim();
            const chatRoomId = '${chatRoom.id}';
            const sender = document.getElementById('sender').value.trim();
            
            if (!message) {
                alert('메시지를 입력하세요.');
                return;
            }         
            
            if (isWhisperMode && whisperRecipient) {
                $.ajax({
                    url: '${pageContext.request.contextPath}/chat/sendWhisper',
                    type: 'POST',
                    data: JSON.stringify({
                        recipient: whisperRecipient,
                        message: message,
                        chatRoomId: chatRoomId,
                        sender: sender
                    }),
                    contentType: 'application/json',
                    success: function(response) {
                        const chatContent = document.getElementById('chatContent');
                        if (response.whisper) {
                            if (response.sender === sender || response.recipient === whisperRecipient) {
                                chatContent.innerHTML += '<p class="whisper">' + '[귓] ' + response.sender + " -> " + response.recipient + ': ' + response.message + '</p>';
                            }
                        }
                        document.getElementById('message').value = '';
                        isWhisperMode = false; // 귓속말 모드 해제
                        whisperRecipient = null; // 귓속말 대상자 초기화
                    },
                    error: function(xhr, status, error) {
                        console.error('Error:', error);
                        alert('귓속말 전송에 실패했습니다.');
                        isWhisperMode = false; // 귓속말 모드 해제
                        whisperRecipient = null; // 귓속말 대상자 초기화
                    }
                });
            } else {
                $.ajax({
                    url: '${pageContext.request.contextPath}/chat/sendMessage',
                    type: 'POST',
                    data: JSON.stringify({
                        message: message,
                        chatRoomId: chatRoomId,
                        sender: sender
                    }),
                    contentType: 'application/json',
                    success: function(response) {
                        const chatContent = document.getElementById('chatContent');
                        chatContent.innerHTML += '<p>' + response.sender + ': ' + response.message + '</p>';
                        document.getElementById('message').value = '';
                    },
                    
                });
            }
        });
        
        // 강퇴버튼
        $(document).on('click', '.kick-button', function() {
        	const userId = $(this).closest('li').data('user-id');
         	// userId가 유효한지 확인
            if (!userId) {
                alert('유효하지 않은 사용자 ID입니다.');
                return;
            }
         	
            $.ajax({
                type: 'POST',
                url: '/chat/kickUser',
                contentType: 'application/x-www-form-urlencoded',
                data: {
                	userId: userId,
                	chatRoomId: chatRoomId
                },
                success: function(response) {
                    if (response === 'success') {
                        $('li[data-user-id="' + userId + '"]').remove();
                        alert(userId + "가 강제퇴장 되었습니다.");
                    } else {
                        alert('강퇴 실패!!');
                    }
                },
                error: function(xhr, status, error) {
                    console.error('Error:', status, error);
                }
            });
        });

        // 강제 퇴장 여부 확인
        function checkKickStatus() {
            $.ajax({
                url: '${pageContext.request.contextPath}/chat/checkKickStatus',
                type: 'GET',
                data: { 
                	userId: sender,
                	chatRoomId: chatRoomId 
                },
                success: function(response) {
                    if (response.kicked) {
                        alert('강제 퇴장 되었습니다.');
                        window.location.href = '${pageContext.request.contextPath}/chat/chatList';
                    }
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.log('Error: ' + textStatus);
                    console.log('Error Thrown: ' + errorThrown);
                }
            });
        }

        // 실시간 메시지 업데이트
        function getMessages() {
            $.ajax({
                url: '${pageContext.request.contextPath}/chat/getMessages',
                type: 'GET',
                data: {
                    chatRoomId: chatRoomId
                },
                success: function(response) {
                    const chatContent = document.getElementById('chatContent');
                    const currentSender = $('#sender').val();
                    const currentRecipient = $('#recipient').val();
                    chatContent.innerHTML = ''; // 기존 메시지를 지우지 않음
                    response.forEach(function(message) {
                        if (message.whisper) {
                            if (message.sender === currentSender || message.recipient === currentRecipient) {
                                chatContent.innerHTML += '<p class="whisper">' + '[귓] ' + message.sender + " -> " + message.recipient + ': ' + message.message + '</p>';
                            }
                        } else {
                            chatContent.innerHTML += '<p>' + message.sender + ': ' + message.message + '</p>';
                        }
                    });
                }
            });
        }

        // 입장 시 접속자 목록 업데이트
        function getUsers() {
        	const chatRoomId = $('#chatRoomId').val();
            $.ajax({
                url: '${pageContext.request.contextPath}/chat/getUsersInRoom',
                type: 'GET',
                data: { 
                	chatRoomId: chatRoomId 
                },
                success: function(users) {
                    const userList = document.getElementById('userList');
                    userList.innerHTML = '';
                    users.forEach(function(user) {
                        const isHost = user.memberId === chatRoomHost;
                        const isCurrentUserHost = sender === chatRoomHost;
                        userList.innerHTML += '<li data-user-id="' + user.userId + '" data-username="' + user.name + '">' +
                            user.name + (isHost ? ' (방장)' : '') +
                            '<button class="whisperButton">귓속말</button>' +
                            (isCurrentUserHost && !isHost ? '<button class="kick-button" data-user-id="' + user.userId + '">강퇴</button>' : '') +
                        '</li>';
                    });
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.log('Error: ' + textStatus);
                    console.log('Error Thrown: ' + errorThrown);
                }
            });
        }

        setInterval(getUsers, 500);
        setInterval(getMessages, 500);
        setInterval(checkKickStatus, 1000);
    </script>
</body>
</html>
