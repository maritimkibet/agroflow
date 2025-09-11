---
inclusion: always
---

# AgroFlow Project Context

## Project Overview
AgroFlow is a farmer-first mobile application built with Flutter and Firebase, designed to empower farmers with modern digital tools while maintaining simplicity and offline capabilities.

## Core Architecture Principles
- **Offline-First**: Use Hive for local storage with Firebase sync
- **Farmer-Centric Design**: Simple, intuitive UI optimized for agricultural workflows
- **Real-time Collaboration**: Firebase Realtime Database for messaging and marketplace
- **Cross-Platform**: Flutter for consistent experience across devices

## Key Features Implementation
- **Calendar & Reminders**: Local Hive storage with visual calendar interface
- **Marketplace**: Firebase Firestore with image upload capabilities
- **Weather Integration**: Location-based weather API with crop suggestions
- **AI Assistant**: Local AI chatbot for agricultural advice
- **WhatsApp Integration**: Direct communication between buyers and sellers

## Development Standards
- Follow Flutter best practices and Material Design guidelines
- Implement proper error handling and offline fallbacks
- Use dependency injection for services
- Maintain clean separation between UI, business logic, and data layers
- Ensure responsive design for various screen sizes

## Firebase Services Used
- Authentication for user management
- Firestore for marketplace and user profiles
- Realtime Database for messaging
- Storage for product images
- Functions for backend processing

## Code Organization
- `lib/models/` - Data models with Hive adapters
- `lib/services/` - Business logic and API integrations
- `lib/screens/` - UI screens organized by feature
- `lib/widgets/` - Reusable UI components
- `lib/auth/` - Authentication flows