<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<html>
<head>
    <title>채팅방 만들기</title>
</head>
<body>
    <form action="${pageContext.request.contextPath}/chat/chatCreate" method="post">
        <label for="name">채팅방명:</label>
        <input type="text" id="name" name="name"><br>

        <label for="password">비밀번호:</label>
        <input type="text" id="password" name="password"><br>

        <label for="limit">인원제한:</label>
        <select id="limit" name="limit">
            <option value="5">5</option>
            <option value="10">10</option>
            <option value="50">50</option>
            <option value="100">100</option>
            <option value="500">500</option>
            <option value="1000">1000</option>
        </select><br>
        <div class="form-group">
            <input type="submit" value="채팅방 만들기">
        </div>
    </form>
</body>
</html>
