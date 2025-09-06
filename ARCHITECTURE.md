# Thakii Lecture2PDF Service - Complete Architecture Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Current Architecture](#current-architecture)
3. [Component Deep Dive](#component-deep-dive)
4. [Data Flow](#data-flow)
5. [Technology Stack](#technology-stack)
6. [Repository Split Strategy](#repository-split-strategy)
7. [Migration Plan](#migration-plan)
8. [Infrastructure Considerations](#infrastructure-considerations)

## Project Overview

The Thakii Lecture2PDF Service is a comprehensive system that converts lecture videos into readable PDF documents. It combines video processing, subtitle generation, image extraction, and PDF creation into a seamless user experience with real-time status updates and cloud storage integration.

### Key Features
- **Video Upload & Processing**: Upload videos up to 2GB
- **Automatic Subtitle Generation**: Using speech recognition
- **PDF Generation**: Extract key frames and combine with subtitles
- **Real-time Updates**: Live status tracking via Firestore
- **User Authentication**: Firebase-based auth system
- **Admin Management**: Multi-level admin system with server management
- **Load Balancing**: AWS Lambda router with circuit breaker pattern
- **Cloud Storage**: S3 for videos, subtitles, and PDFs
- **Scalable Processing**: Background worker system

## Current Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   React Web    │    │   AWS Lambda     │    │   Backend API       │
│   Frontend      │◄──►│   Router         │◄──►│   (Flask)           │
│   (Port 3000)   │    │   (Load Balancer)│    │   (Port 5001)       │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
         │                                                   │
         │              ┌──────────────────┐                │
         └─────────────►│   Firebase       │◄───────────────┘
                        │   (Auth + DB)    │
                        └──────────────────┘
                                 │
                        ┌──────────────────┐    ┌─────────────────────┐
                        │   Background     │    │   lecture2pdf       │
                        │   Worker         │◄──►│   External Engine   │
                        │   (Processing)   │    │   (PDF Generation)  │
                        └──────────────────┘    └─────────────────────┘
                                 │
                        ┌──────────────────┐
                        │   Amazon S3      │
                        │   (File Storage) │
                        └──────────────────┘
```

### Component Distribution
```
lecture2pdf-service/
├── web/                    # Frontend Application
├── backend/                # Backend Services
│   ├── api/               # Flask API Server
│   ├── worker/            # Background Processing
│   ├── core/              # Shared Services
│   └── lecture2pdf-external/  # PDF Generation Engine
├── router/                # AWS Lambda Router
├── docs/                  # Documentation
└── deployment/            # Infrastructure & Scripts
```

## Component Deep Dive

### 1. Frontend Application (`web/`)

**Technology**: React 18 + Vite + Firebase SDK
**Port**: 3000
**Purpose**: User interface for video upload, status tracking, and admin management

#### Key Components:
- **Authentication System**: Firebase Auth integration
- **File Upload**: Drag & drop with progress tracking
- **Real-time Updates**: Firestore listeners for live status
- **Admin Dashboard**: Server management and user administration
- **Responsive Design**: Mobile-friendly interface

#### Key Files:
```
web/src/
├── components/
│   ├── Auth/              # Authentication components
│   ├── FileUpload.jsx     # Video upload interface
│   ├── VideoList.jsx      # Status tracking display
│   └── AdminDashboard.jsx # Admin management
├── contexts/
│   └── AuthContext.jsx    # Global auth state
├── services/
│   ├── api.js            # Backend API calls
│   ├── firestore.js      # Real-time data sync
│   └── notifications.js   # Push notifications
└── config/
    └── firebase.js        # Firebase configuration
```

#### Features:
- **Automatic Polling Disabled**: Manual refresh only (as per recent fixes)
- **File Validation**: Size (2GB max) and type checking
- **Progress Tracking**: Real-time upload progress
- **Error Handling**: Comprehensive error states
- **Admin Features**: Server health monitoring, user management

### 2. Backend API (`backend/api/`)

**Technology**: Flask + Firebase Admin SDK + AWS SDK
**Port**: 5001
**Purpose**: RESTful API for authentication, file management, and task coordination

#### Key Endpoints:
```
GET  /health              # Service health check
POST /upload              # Video upload to S3
GET  /list                # User's video list
GET  /download/{video_id} # Generate presigned S3 URLs
GET  /admin/*             # Admin management endpoints
```

#### Key Files:
```
backend/api/
└── app.py                # Main Flask application

backend/core/
├── auth_middleware.py    # Firebase token verification
├── s3_storage.py         # AWS S3 operations
├── firestore_db.py       # Firestore database operations
├── admin_manager.py      # Admin user management
└── server_manager.py     # Processing server management
```

#### Features:
- **JWT Authentication**: Firebase token verification
- **S3 Integration**: Direct file upload/download
- **Firestore Integration**: Real-time task management
- **CORS Support**: Configurable origins
- **Admin System**: Role-based access control
- **Error Handling**: Comprehensive error responses

### 3. Background Worker (`backend/worker/`)

**Technology**: Python + OpenCV + Speech Recognition
**Purpose**: Process queued videos and generate PDFs

#### Processing Pipeline:
```
1. Monitor Firestore for "in_queue" tasks
2. Download video from S3
3. Generate subtitles using speech recognition
4. Extract key frames using computer vision
5. Generate PDF with frames + subtitles
6. Upload results to S3
7. Update task status to "done" or "failed"
```

#### Key Files:
```
backend/worker/
└── worker.py             # Main worker loop

Integration with lecture2pdf-external:
- subtitle_generator.py   # Speech-to-text processing
- video_segment_finder.py # Key frame extraction
- content_segment_exporter.py # PDF generation
```

#### Features:
- **Continuous Processing**: Infinite loop with error recovery
- **Temp File Management**: Automatic cleanup
- **Multiple Workers**: Can run multiple instances
- **Error Handling**: Failed tasks marked appropriately
- **Logging**: Comprehensive processing logs

### 4. PDF Generation Engine (`backend/lecture2pdf-external/`)

**Technology**: OpenCV + FPDF + Speech Recognition
**Purpose**: Core video-to-PDF conversion logic

#### Processing Steps:
```
1. Video Analysis: Extract frames and detect scene changes
2. Frame Selection: Identify key frames representing slides
3. Subtitle Generation: Convert speech to text with timestamps
4. Content Segmentation: Match subtitles to corresponding frames
5. PDF Creation: Combine frames and text into readable PDF
```

#### Key Algorithms:
- **Scene Change Detection**: Computer vision for slide transitions
- **Frame Deduplication**: Remove similar consecutive frames
- **Speech Recognition**: Audio-to-text conversion
- **Layout Engine**: PDF formatting with images and text

#### Key Files:
```
src/
├── main.py                    # Main entry point
├── video_segment_finder.py    # Frame extraction logic
├── subtitle_generator.py      # Speech recognition
├── subtitle_segment_finder.py # Text-frame matching
├── content_segment_exporter.py # PDF generation
└── subtitle_parsers/          # SRT/VTT parsing
```

### 5. AWS Lambda Router (`router/`)

**Technology**: AWS Lambda + API Gateway + Python
**Purpose**: Load balancing and circuit breaking for backend services

#### Features:
- **Priority-based Routing**: Route to highest priority available server
- **Circuit Breaker**: Automatic failure detection and recovery
- **Health Monitoring**: Regular health checks
- **Fallback Mechanism**: Automatic failover to backup servers
- **Request Forwarding**: Transparent proxy with full request/response

#### Configuration:
```json
{
  "ai_services": [
    {
      "name": "primary-server",
      "url": "https://api.primary.com",
      "priority": 1,
      "timeout": 300,
      "enabled": true
    }
  ],
  "circuit_breaker": {
    "failure_threshold": 5,
    "recovery_timeout": 60
  }
}
```

### 6. Data Storage

#### Firebase Firestore Collections:
```
video_tasks/{video_id}
├── filename: string
├── user_id: string
├── user_email: string
├── status: "in_queue" | "in_progress" | "done" | "failed"
├── upload_date: timestamp
├── created_at: timestamp
└── updated_at: timestamp

admin_users/{user_id}
├── email: string
├── role: "admin" | "super_admin"
├── status: "active" | "inactive"
└── permissions: object

processing_servers/{server_id}
├── name: string
├── url: string
├── status: "healthy" | "unhealthy"
├── last_health_check: timestamp
└── load_metrics: object

notifications/{notification_id}
├── user_id: string
├── type: string
├── message: string
├── read: boolean
└── created_at: timestamp
```

#### Amazon S3 Structure:
```
thakii-video-storage/
├── videos/{video_id}/{filename}     # Original uploads
├── subtitles/{video_id}.srt         # Generated subtitles
└── pdfs/{video_id}.pdf              # Generated PDFs
```

## Data Flow

### Upload Flow:
```
1. User uploads video via React frontend
2. Frontend calls /upload API endpoint
3. Backend uploads video to S3
4. Backend creates task in Firestore ("in_queue")
5. Frontend receives success response
6. Real-time listeners update UI status
```

### Processing Flow:
```
1. Worker polls Firestore for "in_queue" tasks
2. Worker updates task status to "in_progress"
3. Worker downloads video from S3
4. Worker generates subtitles using speech recognition
5. Worker extracts key frames using computer vision
6. Worker generates PDF combining frames + subtitles
7. Worker uploads PDF and subtitles to S3
8. Worker updates task status to "done"
9. Frontend receives real-time update via Firestore
```

### Download Flow:
```
1. User clicks download button
2. Frontend calls /download/{video_id} endpoint
3. Backend verifies user ownership/permissions
4. Backend generates presigned S3 URL (expires in 1 hour)
5. Backend returns download URL to frontend
6. Frontend triggers browser download
```

## Technology Stack

### Frontend:
- **React 18**: Modern React with hooks
- **Vite**: Fast build tool and dev server
- **Firebase SDK**: Authentication and real-time database
- **Axios**: HTTP client for API calls
- **Tailwind CSS**: Utility-first CSS framework
- **React Hot Toast**: User notifications
- **Lucide React**: Modern icon library

### Backend:
- **Flask**: Python web framework
- **Firebase Admin SDK**: Server-side Firebase integration
- **AWS SDK (boto3)**: S3 and other AWS services
- **Flask-CORS**: Cross-origin resource sharing
- **python-dotenv**: Environment variable management

### Processing:
- **OpenCV**: Computer vision for video processing
- **SpeechRecognition**: Audio-to-text conversion
- **FPDF**: PDF generation library
- **webvtt-py**: Subtitle format parsing
- **Pillow**: Image processing

### Infrastructure:
- **AWS Lambda**: Serverless routing
- **AWS API Gateway**: API management
- **AWS S3**: Object storage
- **Firebase Firestore**: NoSQL database
- **Firebase Authentication**: User management
- **GitHub Actions**: CI/CD pipeline

## Repository Split Strategy

The current monorepo should be split into 6 focused repositories for better maintainability, deployment, and team collaboration.

### Proposed Repository Structure:

#### 1. `thakii-frontend` 
**Purpose**: React web application
**Technology**: React + Vite + Firebase SDK
**Team**: Frontend developers
**Deployment**: Static hosting (Vercel/Netlify/S3)

```
thakii-frontend/
├── src/
├── public/
├── package.json
├── vite.config.js
├── tailwind.config.js
├── .env.example
├── README.md
└── deployment/
    ├── vercel.json
    └── netlify.toml
```

**Dependencies**: 
- External: Firebase, Backend API
- Internal: None

#### 2. `thakii-backend-api`
**Purpose**: Flask REST API server
**Technology**: Flask + Firebase Admin + AWS SDK
**Team**: Backend developers
**Deployment**: Docker containers (ECS/EC2)

```
thakii-backend-api/
├── api/
├── core/
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── README.md
└── deployment/
    ├── ecs-task-definition.json
    └── github-actions/
```

**Dependencies**:
- External: Firebase, S3, Lambda Router
- Internal: None (standalone API)

#### 3. `thakii-worker-service`
**Purpose**: Background video processing
**Technology**: Python + OpenCV + lecture2pdf-engine
**Team**: Backend/ML developers
**Deployment**: Docker containers or systemd services

```
thakii-worker-service/
├── worker/
├── requirements.txt
├── Dockerfile
├── .env.example
├── README.md
└── deployment/
    ├── systemd/
    └── docker/
```

**Dependencies**:
- External: Firebase, S3
- Internal: thakii-pdf-engine (as package dependency)

#### 4. `thakii-pdf-engine`
**Purpose**: Core video-to-PDF conversion library
**Technology**: Python + OpenCV + FPDF
**Team**: ML/Computer Vision developers
**Deployment**: PyPI package

```
thakii-pdf-engine/
├── thakii_pdf_engine/
│   ├── __init__.py
│   ├── video_processor.py
│   ├── subtitle_generator.py
│   ├── pdf_builder.py
│   └── utils/
├── tests/
├── docs/
├── setup.py
├── pyproject.toml
├── requirements.txt
├── README.md
└── examples/
```

**Dependencies**:
- External: OpenCV, FPDF, SpeechRecognition
- Internal: None (standalone library)

#### 5. `thakii-lambda-router`
**Purpose**: AWS Lambda load balancer
**Technology**: AWS Lambda + API Gateway
**Team**: DevOps/Infrastructure
**Deployment**: AWS Lambda via Terraform/CloudFormation

```
thakii-lambda-router/
├── src/
│   ├── lambda_function.py
│   ├── service_manager.py
│   └── config_loader.py
├── config/
├── tests/
├── requirements.txt
├── README.md
└── deployment/
    ├── terraform/
    ├── cloudformation/
    └── deploy.sh
```

**Dependencies**:
- External: AWS SDK
- Internal: None

#### 6. `thakii-infrastructure`
**Purpose**: Infrastructure as Code and deployment scripts
**Technology**: Terraform + GitHub Actions + Docker
**Team**: DevOps
**Deployment**: CI/CD pipelines

```
thakii-infrastructure/
├── terraform/
│   ├── environments/
│   ├── modules/
│   └── variables.tf
├── github-actions/
├── docker/
├── scripts/
├── monitoring/
├── README.md
└── docs/
```

**Dependencies**:
- External: AWS, GitHub Actions
- Internal: Orchestrates all other repositories

### Repository Relationships:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ thakii-frontend │───►│thakii-lambda-    │───►│ thakii-backend-api  │
│                 │    │router            │    │                     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                          │
                                                          ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ thakii-pdf-     │◄───│ thakii-worker-   │◄───│ Firebase/S3         │
│ engine          │    │ service          │    │                     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
         ▲                                                ▲
         │                                                │
         └────────────────────────────────────────────────┘
                    ┌──────────────────┐
                    │ thakii-          │
                    │ infrastructure   │
                    └──────────────────┘
```

## Migration Plan

### Phase 1: Repository Setup (Week 1)
1. **Create new repositories** with proper GitHub settings
2. **Set up branch protection rules** and CI/CD pipelines
3. **Configure repository permissions** and team access
4. **Create initial documentation** and README files

### Phase 2: Code Migration (Week 2-3)
1. **Extract PDF Engine** as standalone Python package
2. **Migrate Frontend** with updated API endpoints
3. **Split Backend API** from worker service
4. **Extract Worker Service** with PDF engine dependency
5. **Migrate Lambda Router** with infrastructure code

### Phase 3: CI/CD Setup (Week 3-4)
1. **Set up GitHub Actions** for each repository
2. **Configure automated testing** and code quality checks
3. **Set up deployment pipelines** for each service
4. **Configure monitoring** and alerting

### Phase 4: Documentation & Training (Week 4-5)
1. **Create comprehensive documentation** for each repository
2. **Set up development environments** and onboarding guides
3. **Train team members** on new repository structure
4. **Create troubleshooting guides** and runbooks

### Phase 5: Production Migration (Week 5-6)
1. **Deploy services** from new repositories to staging
2. **Run integration tests** across all services
3. **Migrate production** with zero-downtime deployment
4. **Monitor and optimize** post-migration

### Migration Checklist:

#### Pre-Migration:
- [ ] Backup all current code and data
- [ ] Document current dependencies and integrations
- [ ] Set up new GitHub repositories with proper settings
- [ ] Create migration timeline and assign responsibilities

#### During Migration:
- [ ] Extract shared utilities into common packages
- [ ] Update import paths and dependencies
- [ ] Migrate environment variables and secrets
- [ ] Update CI/CD configurations
- [ ] Test inter-service communication

#### Post-Migration:
- [ ] Archive old monorepo (read-only)
- [ ] Update documentation and team processes
- [ ] Monitor service health and performance
- [ ] Collect feedback and iterate on improvements

## Infrastructure Considerations

### Deployment Strategy:
- **Frontend**: Static hosting with CDN (Vercel/Netlify)
- **Backend API**: Containerized deployment (AWS ECS/EKS)
- **Worker Service**: Background service (ECS/EC2 with auto-scaling)
- **Lambda Router**: Serverless (AWS Lambda + API Gateway)
- **PDF Engine**: PyPI package for easy distribution

### Security:
- **Repository Access**: Role-based permissions per repository
- **Secrets Management**: GitHub Secrets + AWS Parameter Store
- **API Security**: JWT tokens + CORS configuration
- **Network Security**: VPC + Security Groups for AWS resources

### Monitoring:
- **Application Monitoring**: CloudWatch + Application Insights
- **Error Tracking**: Sentry for error aggregation
- **Performance**: APM tools for service performance
- **Logs**: Centralized logging with ELK stack

### Scalability:
- **Horizontal Scaling**: Auto-scaling groups for workers
- **Load Balancing**: Application Load Balancer + Lambda router
- **Database**: Firestore with proper indexing
- **Storage**: S3 with CloudFront CDN

### Cost Optimization:
- **Serverless**: Lambda for routing reduces idle costs
- **Auto-scaling**: Scale workers based on queue depth
- **Storage Lifecycle**: S3 lifecycle policies for old files
- **Reserved Instances**: For predictable backend loads

## Benefits of Repository Split

### Development Benefits:
- **Focused Development**: Teams can work on specific services
- **Independent Releases**: Deploy services independently
- **Technology Flexibility**: Use different tech stacks per service
- **Code Quality**: Smaller codebases are easier to maintain

### Operational Benefits:
- **Scalability**: Scale services independently based on load
- **Reliability**: Service failures don't affect other components
- **Security**: Limit access to sensitive components
- **Compliance**: Easier to audit and secure individual services

### Business Benefits:
- **Faster Development**: Parallel development across teams
- **Reduced Risk**: Changes isolated to specific services
- **Cost Efficiency**: Pay only for resources each service needs
- **Market Agility**: Faster feature delivery and iteration

This architecture documentation provides a comprehensive understanding of the current system and a clear path forward for splitting into multiple repositories while maintaining system integrity and improving development velocity.
