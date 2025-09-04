# AI File Sorting Implementation

This document details the implementation of the AI-powered file sorting extension for the Raspberry Pi NAS project.

## Overview

The AI file sorting extension automatically organizes files uploaded to the NAS based on file type, content, and metadata. This intelligent system eliminates the need for manual file organization, saving time and ensuring consistent organization across all stored files.

## Features

### 1. Automatic File Classification

Files are automatically categorized based on:
- File extensions
- Content analysis
- Metadata extraction
- Usage patterns

### 2. Real-time Processing

- Files are processed immediately upon upload
- No delay in availability of organized content
- Background processing with minimal resource impact

### 3. AI-Enhanced Categorization

Beyond simple extension-based sorting, the system implements:
- Document content classification (work, personal, academic)
- Image scene recognition and categorization
- Duplicate file detection and management
- EXIF data extraction for photos (date, location)

## Implementation Details

### Core Components

#### 1. File Monitoring System

The system uses `watchdog` to monitor the shared directories for new files:

```python
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import os, shutil, time

class FileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory:
            # Allow file to finish uploading
            time.sleep(1)
            # Process the file
            process_file(event.src_path)
            
observer = Observer()
event_handler = FileHandler()
observer.schedule(event_handler, "/home/pi/shared", recursive=False)
observer.start()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
observer.join()
```

#### 2. File Type Classification

Basic classification based on file extensions:

```python
def classify_by_extension(file_path):
    ext = os.path.splitext(file_path)[1].lower()
    
    # Define category mappings
    categories = {
        'images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff'],
        'documents': ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.xls', '.xlsx', '.ppt', '.pptx'],
        'audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'],
        'video': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm'],
        'archives': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'],
        'code': ['.py', '.js', '.html', '.css', '.java', '.cpp', '.c', '.php']
    }
    
    for category, extensions in categories.items():
        if ext in extensions:
            return category
            
    return 'others'
```

#### 3. Content-Based Classification

For documents, implement content-based classification:

```python
def classify_document_content(file_path):
    # Extract text content based on file type
    text_content = extract_text(file_path)
    
    # Skip if text extraction failed
    if not text_content:
        return None
        
    # Analyze with pre-trained classifier
    category = document_classifier.predict([text_content])[0]
    
    return category
```

#### 4. Image Analysis

For images, implement scene recognition and face detection:

```python
def analyze_image(image_path):
    # Load image
    image = cv2.imread(image_path)
    if image is None:
        return None
        
    # Resize for efficiency
    image = cv2.resize(image, (224, 224))
    
    # Predict scene category
    scene_category = scene_classifier.predict(np.expand_dims(image, axis=0))[0]
    
    # Detect faces if present
    faces = face_detector.detectMultiScale(image)
    has_faces = len(faces) > 0
    
    return {
        'scene': scene_category,
        'has_people': has_faces,
        'face_count': len(faces)
    }
```

#### 5. File Organization

After classification, move files to appropriate folders:

```python
def organize_file(file_path, classifications):
    file_name = os.path.basename(file_path)
    base_dir = "/home/pi/shared"
    
    # Determine target directory based on classifications
    primary_category = classifications.get('primary_category', 'others')
    
    # Create more specific subcategory if available
    subcategory = classifications.get('subcategory', '')
    
    # Create target directory path
    if subcategory:
        target_dir = os.path.join(base_dir, primary_category, subcategory)
    else:
        target_dir = os.path.join(base_dir, primary_category)
    
    # Create directory if it doesn't exist
    os.makedirs(target_dir, exist_ok=True)
    
    # Move the file
    target_path = os.path.join(target_dir, file_name)
    shutil.move(file_path, target_path)
    
    return target_path
```

### Processing Pipeline

The complete processing pipeline combines all components:

1. File detected by watchdog
2. Basic classification by file extension
3. Enhanced classification based on file type:
   - Documents → content analysis
   - Images → scene/face recognition
   - Audio/Video → metadata extraction
4. Duplicate detection
5. File organization into appropriate directory structure
6. Optional tagging and metadata enrichment

## Service Configuration

The file sorting service is configured to run automatically at system startup:

```
[Unit]
Description=AI File Sorting Service
After=network.target smbd.service

[Service]
ExecStart=/usr/bin/python3 /home/pi/file_sorter.py
Restart=always
User=pi
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

## Performance Considerations

To ensure optimal performance on the Raspberry Pi:

1. **Resource Management**:
   - Limit concurrent file processing
   - Implement processing queue for large batches
   - Schedule intensive operations during low-usage periods

2. **Optimization Techniques**:
   - Use lightweight models for AI classification
   - Progressive processing (quick sort by extension, detailed analysis later)
   - Caching of common file signatures

3. **Monitoring and Management**:
   - Resource usage tracking
   - Processing time metrics
   - Success/failure logging
   - Service status checking
   - File sorting statistics visualization
   - Log analysis utilities

## User Configuration

The system provides several configuration options:

1. **Category Customization**:
   - Add/modify category definitions
   - Define custom sorting rules

2. **Processing Rules**:
   - Ignore specific file types
   - Define priority for certain directories
   - Configure notification preferences

3. **AI Feature Toggles**:
   - Enable/disable specific AI features
   - Adjust processing intensity

## Future Enhancements

1. **Learning from User Behavior**:
   - Track manual file moves
   - Adapt categorization based on user corrections

2. **Advanced Media Analysis**:
   - Audio content recognition
   - Video scene detection
   - Object recognition in images

3. **Integration with Search**:
   - Full-text indexing of documents
   - Content-based search capabilities
   - Semantic relationship mapping

## Conclusion

The AI file sorting extension transforms the basic Raspberry Pi NAS from a simple storage device into an intelligent file management system. By automatically organizing files based on content and context, it significantly improves the user experience while reducing the manual effort typically required to maintain organized file structures.
