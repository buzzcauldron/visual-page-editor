<?php
/**
 * Common code to be executed by other php scripts.
 *
 * @version $Version: 1.2.0$
 * @author buzzcauldron
 * @copyright Copyright(c) 2025, buzzcauldron
 * @license MIT License
 */

// Single source: read from project root VERSION file
$versionFile = __DIR__ . '/../VERSION';
$version = (is_file($versionFile) ? trim(file_get_contents($versionFile)) : '') ?: '1.2.0';
$v = '?v='.$version;

/// User authentication ///
if ( is_file('/var/www/visual-page-editor/data/.htpasswd') ) {
  require_once('htpasswd.inc.php');
  test_htpasswd("/var/www/visual-page-editor/data/.htpasswd","visual-page-editor",3600*24*30);
  $uname = $_COOKIE['PHP_AUTH_USER'];
}
else {
  session_set_cookie_params(3600*24*30);
  session_start();
  if ( isset($_GET['u']) && $_GET['u'] )
    $uname = $_SESSION['u'] = $_GET['u'];
  elseif ( isset($_SESSION['u']) )
    $uname = $_SESSION['u'];
  else
    $uname = 'anonymous';
}

/// Cookie to anonymously identify a browser ///
if ( ! isset($_COOKIE['PHP_AUTH_BR']) ) {
  $_COOKIE['PHP_AUTH_BR'] = base64_encode(random_bytes(6));
  setcookie( 'PHP_AUTH_BR', $_COOKIE['PHP_AUTH_BR'], time()+3600*24*365*10, '/' );
}

/// Forward info for apache logs ///
apache_note( 'uname', $uname.':'.$_COOKIE['PHP_AUTH_BR'] );
