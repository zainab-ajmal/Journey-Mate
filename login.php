<?php
include('server.php')

?>
<!DOCTYPE html>
<html>
<body>

<form action="server.php" method="post">
  <div class="imgcontainer">
<center>
</p>
    <img src="img_avatar2.png" alt="Avatar" class="avatar">
<center>
</p>

  </div>

  <div class="container">
<center>
    <label for="uname"><b>Username</b></label>
    <input type="text" placeholder="Enter Username" name="uname" required>
<center>
    <label for="psw"><b>Password</b></label>
    <input type="password" placeholder="Enter Password" name="psw" required>
<center>
    <button type="submit">Login</button>
    <label>
<center>
      <input type="checkbox" checked="checked" name="remember"> Remember me
    </label>
  </div>

  <div class="container" style="background-color:#f1f1f1">
<center>
    <button type="button" onclick=" location.href='index.php'"class="cancelbtn">Cancel</button>
<center>
    <span class="psw">Forgot <a href="#">password?</a></span>
  </div>
  </p>
<center>
  		Not yet a member? <a href>Sign up</a>
  	

</form>

</body>
</html>
