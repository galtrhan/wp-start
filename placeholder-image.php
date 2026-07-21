<?php
/**
 * Missing uploads fallback for random_placeholder mode: redirect to a deterministic JPG.
 *
 * Each missing upload path gets a stable seed so the same URL always shows the same photo.
 * Offline placeholder mode uses /placeholder.jpg instead (see scripts/fetch-placeholder.sh).
 */
declare(strict_types=1);

$path = $_GET['path'] ?? $_SERVER['REQUEST_URI'] ?? '';
if (! is_string($path) || $path === '') {
    http_response_code(400);
    exit('Bad request');
}

$width  = max(100, min(2400, (int) ($_GET['w'] ?? 1200)));
$height = max(100, min(2400, (int) ($_GET['h'] ?? 800)));

$provider = getenv('PLACEHOLDER_PHOTO_PROVIDER') ?: 'picsum';
$seed     = md5($path);

switch ($provider) {
    case 'picsum':
    default:
        $url = sprintf('https://picsum.photos/seed/%s/%d/%d.jpg', $seed, $width, $height);
        break;
}

header('Location: ' . $url, true, 302);
header('Cache-Control: public, max-age=86400');
exit;
