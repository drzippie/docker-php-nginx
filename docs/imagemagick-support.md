# ImageMagick Support

This Docker image includes ImageMagick and the PHP Imagick extension for advanced image manipulation capabilities.

## What's Included

- **ImageMagick**: The underlying image manipulation library
- **PHP Imagick Extension**: PHP bindings for ImageMagick functionality

## Basic Usage

The Imagick extension is automatically available in PHP. Here's a simple example:

```php
<?php
// Create a new Imagick object
$image = new Imagick();

// Read an image
$image->readImage('/path/to/image.jpg');

// Resize the image
$image->scaleImage(200, 200);

// Save the processed image
$image->writeImage('/path/to/output.jpg');

// Clean up
$image->clear();
$image->destroy();
?>
```

## Common Operations

### Image Resizing
```php
<?php
$image = new Imagick('input.jpg');
$image->resizeImage(800, 600, Imagick::FILTER_LANCZOS, 1);
$image->writeImage('resized.jpg');
?>
```

### Image Format Conversion
```php
<?php
$image = new Imagick('input.jpg');
$image->setImageFormat('png');
$image->writeImage('output.png');
?>
```

### Adding Watermarks
```php
<?php
$image = new Imagick('photo.jpg');
$watermark = new Imagick('watermark.png');

// Position watermark at bottom right
$image->compositeImage($watermark, Imagick::COMPOSITE_OVER, 
    $image->getImageWidth() - $watermark->getImageWidth() - 10,
    $image->getImageHeight() - $watermark->getImageHeight() - 10);

$image->writeImage('watermarked.jpg');
?>
```

## Configuration

### Memory Limits
For large image processing, you may need to adjust PHP memory limits:

```ini
memory_limit = 512M
```

### ImageMagick Limits
You can configure ImageMagick limits by mounting a custom policy file:

```bash
docker run -v "`pwd`/policy.xml:/etc/ImageMagick-7/policy.xml" drzippie/php-nginx
```

Example policy.xml:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policymap [
<!ELEMENT policymap (policy)+>
<!ELEMENT policy (#PCDATA)>
<!ATTLIST policy domain (delegate|coder|filter|path|resource) #IMPLIED>
<!ATTLIST policy name CDATA #IMPLIED>
<!ATTLIST policy rights CDATA #IMPLIED>
<!ATTLIST policy pattern CDATA #IMPLIED>
<!ATTLIST policy value CDATA #IMPLIED>
]>
<policymap>
  <policy domain="resource" name="memory" value="512MiB"/>
  <policy domain="resource" name="map" value="512MiB"/>
  <policy domain="resource" name="area" value="128MB"/>
  <policy domain="resource" name="disk" value="1GiB"/>
</policymap>
```

## Supported Formats

The included ImageMagick installation supports common image formats:

- **JPEG** (.jpg, .jpeg)
- **PNG** (.png)
- **GIF** (.gif)
- **TIFF** (.tiff, .tif)
- **BMP** (.bmp)
- **WebP** (.webp)
- **SVG** (.svg)
- **PDF** (.pdf)

## Performance Tips

1. **Use appropriate filters**: `FILTER_LANCZOS` for high quality, `FILTER_TRIANGLE` for speed
2. **Clean up objects**: Always call `clear()` and `destroy()` to free memory
3. **Process in batches**: For multiple images, process them in smaller batches
4. **Set resource limits**: Configure memory and disk limits appropriately

## Troubleshooting

### Common Issues

**"No decode delegate for this image format"**
- The image format may not be supported or enabled
- Check available formats with: `Imagick::queryFormats()`

**Memory exhaustion**
- Increase PHP memory_limit
- Configure ImageMagick resource limits
- Process images in smaller batches

**Permission errors**
- Ensure the web server has read/write permissions to image directories
- Check that the `nobody` user can access the files

### Checking Installation

Verify ImageMagick is working:

```php
<?php
echo "ImageMagick Version: " . Imagick::getVersion()['versionString'] . "\n";
echo "Supported formats: " . implode(', ', Imagick::queryFormats()) . "\n";
?>
```

## Security Considerations

1. **Validate input**: Always validate uploaded image files
2. **Limit file sizes**: Set appropriate upload limits
3. **Sanitize filenames**: Prevent directory traversal attacks
4. **Use resource limits**: Configure memory and processing limits
5. **Disable dangerous formats**: Consider disabling formats like SVG if not needed

## Examples

### Complete Image Upload Handler
```php
<?php
function processUploadedImage($uploadedFile, $outputPath, $maxWidth = 1200) {
    try {
        // Validate file
        if (!is_uploaded_file($uploadedFile['tmp_name'])) {
            throw new Exception('Invalid upload');
        }
        
        // Create Imagick object
        $image = new Imagick($uploadedFile['tmp_name']);
        
        // Get original dimensions
        $width = $image->getImageWidth();
        $height = $image->getImageHeight();
        
        // Resize if needed
        if ($width > $maxWidth) {
            $newHeight = ($height * $maxWidth) / $width;
            $image->resizeImage($maxWidth, $newHeight, Imagick::FILTER_LANCZOS, 1);
        }
        
        // Optimize
        $image->setImageCompression(Imagick::COMPRESSION_JPEG);
        $image->setImageCompressionQuality(85);
        
        // Save
        $image->writeImage($outputPath);
        
        // Clean up
        $image->clear();
        $image->destroy();
        
        return true;
    } catch (Exception $e) {
        error_log("Image processing error: " . $e->getMessage());
        return false;
    }
}
?>
```

For more advanced usage, refer to the [official ImageMagick documentation](https://imagemagick.org/script/php.php).