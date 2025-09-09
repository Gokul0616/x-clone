const express = require('express');
const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const { v4: uuidv4 } = require('uuid');
const { auth } = require('../middleware/auth');
const router = express.Router();


const uploadsDir = path.join(__dirname, '..', 'uploads');
const imagesDir = path.join(uploadsDir, 'images');
const videosDir = path.join(uploadsDir, 'videos');

async function ensureDirectoriesExist() {
  try {
    await fs.mkdir(uploadsDir, { recursive: true });
    await fs.mkdir(imagesDir, { recursive: true });
    await fs.mkdir(videosDir, { recursive: true });
  } catch (error) {
    console.error('Error creating upload directories:', error);
  }
}

ensureDirectoriesExist();


const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {



  const getImageMimeType = (filename) => {
    const ext = filename.toLowerCase().split('.').pop();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp'
    };
    return mimeTypes[ext];
  };

  if (file.fieldname === 'images') {

    const isImageMimetype = file.mimetype.startsWith('image/');
    const expectedMimetype = getImageMimeType(file.originalname);

    if (isImageMimetype || expectedMimetype) {

      if (file.mimetype === 'application/octet-stream' && expectedMimetype) {
        file.mimetype = expectedMimetype;
      }
      console.log('Accepting image file:', file.originalname, 'with mimetype:', file.mimetype);
      cb(null, true);
    } else {
      console.log('Rejecting file:', file.originalname, '- not a valid image file');
      cb(new Error('Only image files are allowed for images field'), false);
    }
  } else if (file.fieldname === 'videos') {
    if (file.mimetype.startsWith('video/')) {
      console.log('Accepting video file:', file.originalname);
      cb(null, true);
    } else {
      console.log('Rejecting file:', file.originalname, '- not a valid video file');
      cb(new Error('Only video files are allowed for videos field'), false);
    }
  } else {
    console.log('Rejecting file:', file.originalname, '- invalid field name:', file.fieldname);
    cb(new Error('Invalid field name'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024,
    files: 10
  }
});


router.post('/images', auth, upload.array('images', 4), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'No image files provided'
      });
    }

    const imageUrls = [];

    for (const file of req.files) {

      const filename = `${uuidv4()}.webp`;
      const filepath = path.join(imagesDir, filename);


      await sharp(file.buffer)
        .resize(1200, 1200, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .webp({ quality: 85 })
        .toFile(filepath);


      const imageUrl = `${process.env.URL}/uploads/images/${filename}`;
      imageUrls.push(imageUrl);
    }

    res.status(200).json({
      status: 'success',
      message: 'Images uploaded successfully',
      imageUrls
    });

  } catch (error) {
    console.error('Image upload error:', error);

    if (error.message.includes('Only image files')) {
      return res.status(400).json({
        status: 'error',
        message: 'Only image files are allowed'
      });
    }

    if (error.message.includes('File too large')) {
      return res.status(400).json({
        status: 'error',
        message: 'File size too large. Maximum size is 10MB'
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Failed to upload images'
    });
  }
});


router.post('/videos', auth, upload.array('videos', 2), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'No video files provided'
      });
    }

    const videoUrls = [];

    for (const file of req.files) {

      const fileExtension = path.extname(file.originalname);
      const filename = `${uuidv4()}${fileExtension}`;
      const filepath = path.join(videosDir, filename);


      await fs.writeFile(filepath, file.buffer);


      const videoUrl = `/uploads/videos/${filename}`;
      videoUrls.push(videoUrl);
    }

    res.status(200).json({
      status: 'success',
      message: 'Videos uploaded successfully',
      videoUrls
    });

  } catch (error) {
    console.error('Video upload error:', error);

    if (error.message.includes('Only video files')) {
      return res.status(400).json({
        status: 'error',
        message: 'Only video files are allowed'
      });
    }

    if (error.message.includes('File too large')) {
      return res.status(400).json({
        status: 'error',
        message: 'File size too large. Maximum size is 10MB'
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Failed to upload videos'
    });
  }
});


router.post('/profile', auth, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        status: 'error',
        message: 'No image file provided'
      });
    }

    const { type } = req.body;

    if (!type || !['profile', 'banner'].includes(type)) {
      return res.status(400).json({
        status: 'error',
        message: 'Type must be either "profile" or "banner"'
      });
    }


    const filename = `${type}_${uuidv4()}.webp`;
    const filepath = path.join(imagesDir, filename);


    let sharpInstance = sharp(req.file.buffer);

    if (type === 'profile') {

      sharpInstance = sharpInstance
        .resize(400, 400, {
          fit: 'cover',
          position: 'center'
        });
    } else if (type === 'banner') {

      sharpInstance = sharpInstance
        .resize(1500, 500, {
          fit: 'cover',
          position: 'center'
        });
    }

    await sharpInstance
      .webp({ quality: 90 })
      .toFile(filepath);


    const imageUrl = `/uploads/images/${filename}`;

    res.status(200).json({
      status: 'success',
      message: `${type} image uploaded successfully`,
      imageUrl
    });

  } catch (error) {
    console.error('Profile image upload error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to upload profile image'
    });
  }
});


router.delete('/:type/:filename', auth, async (req, res) => {
  try {
    const { type, filename } = req.params;

    if (!['images', 'videos'].includes(type)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid file type'
      });
    }

    const directory = type === 'images' ? imagesDir : videosDir;
    const filepath = path.join(directory, filename);


    try {
      await fs.access(filepath);
    } catch (error) {
      return res.status(404).json({
        status: 'error',
        message: 'File not found'
      });
    }


    await fs.unlink(filepath);

    res.status(200).json({
      status: 'success',
      message: 'File deleted successfully'
    });

  } catch (error) {
    console.error('Delete file error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete file'
    });
  }
});


router.get('/info/:type/:filename', async (req, res) => {
  try {
    const { type, filename } = req.params;

    if (!['images', 'videos'].includes(type)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid file type'
      });
    }

    const directory = type === 'images' ? imagesDir : videosDir;
    const filepath = path.join(directory, filename);


    const stats = await fs.stat(filepath);

    res.status(200).json({
      status: 'success',
      file: {
        filename,
        type,
        size: stats.size,
        createdAt: stats.birthtime,
        modifiedAt: stats.mtime
      }
    });

  } catch (error) {
    if (error.code === 'ENOENT') {
      return res.status(404).json({
        status: 'error',
        message: 'File not found'
      });
    }

    console.error('Get file info error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get file info'
    });
  }
});

module.exports = router;