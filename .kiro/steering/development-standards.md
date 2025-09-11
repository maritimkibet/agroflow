---
inclusion: always
---

# Development Standards for AgroFlow

## Code Quality Standards
- Follow Dart/Flutter official style guide
- Use meaningful variable and function names
- Add comprehensive documentation for public APIs
- Implement proper error handling with user-friendly messages
- Write unit tests for critical business logic

## Architecture Patterns
- Use Provider pattern for state management
- Implement repository pattern for data access
- Separate business logic into dedicated service classes
- Use dependency injection for testability
- Follow clean architecture principles

## UI/UX Guidelines
- Implement Material Design 3 components
- Ensure accessibility with proper semantic labels
- Design for offline-first user experience
- Use consistent spacing and typography
- Implement responsive layouts for various screen sizes

## Performance Optimization
- Implement lazy loading for large lists
- Use efficient image caching and compression
- Minimize Firebase read/write operations
- Implement proper pagination for marketplace listings
- Cache frequently accessed data locally

## Security Best Practices
- Never commit sensitive data or API keys
- Use Firebase Security Rules for data protection
- Implement proper input validation
- Use secure storage for sensitive local data
- Follow OWASP mobile security guidelines