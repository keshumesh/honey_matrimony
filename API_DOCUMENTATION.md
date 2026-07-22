# Honey Matrimony API Documentation

This document provides detailed information about the Honey Matrimony REST API used by the React Native app.

## Base URL

**Development**: `http://localhost:3000/api/v1`  
**Production**: `https://your-domain.com/api/v1`

## Authentication

All API endpoints (except `/auth/register` and `/auth/login`) require a Bearer token in the `Authorization` header:

```
Authorization: Bearer {token}
```

## Response Format

All responses are in JSON format. Successful responses follow this structure:

```json
{
  "message": "Description of the action",
  "data": {
    // Response data
  }
}
```

Error responses:

```json
{
  "error": "Error message",
  "errors": ["Error 1", "Error 2"]
}
```

## Endpoints

### Authentication

#### POST `/auth/register`
Register a new user.

**Request**:
```json
{
  "user": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "mobile_no": "9876543210",
    "gender": "Male",
    "dob": "1990-01-15",
    "religion": "Hindu",
    "height": "5'10\"",
    "marital_status": "Never Married",
    "complexion": "Fair",
    "mother_tongue": "Hindi",
    "caste": "Brahmin",
    "highest_educational_details": "Bachelor's",
    "food_type": "Vegetarian",
    "manglik": "No"
  }
}
```

**Response** (201 Created):
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "mobile_no": "9876543210",
    "gender": "Male",
    "dob": "1990-01-15",
    "avatar": null,
    "role": "user"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### POST `/auth/login`
Authenticate user with email and password.

**Request**:
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response** (200 OK):
```json
{
  "message": "Logged in successfully",
  "user": {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "mobile_no": "9876543210",
    "gender": "Male",
    "dob": "1990-01-15",
    "avatar": "http://...",
    "role": "user"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Status Codes**:
- `200 OK` - Login successful
- `401 Unauthorized` - Invalid credentials

#### POST `/auth/logout`
Logout the current user. Client should discard the token.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
{
  "message": "Logged out successfully"
}
```

#### GET `/auth/me`
Get current authenticated user.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
{
  "id": 1,
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "mobile_no": "9876543210",
  "gender": "Male",
  "dob": "1990-01-15",
  "age": 34,
  "height": "5'10\"",
  "religion": "Hindu",
  "caste": "Brahmin",
  "sub_caste": null,
  "marital_status": "Never Married",
  "complexion": "Fair",
  "mother_tongue": "Hindi",
  "job": "Software Engineer",
  "organization_name": "Tech Company",
  "annual_income": "10-15 LPA",
  "food_type": "Vegetarian",
  "manglik": "No",
  "blood_group": "O+",
  "hobbies": "Reading, Gaming",
  "family_details": "Father is doctor",
  "any_requirement": null,
  "avatar": "http://...",
  "gallery_photos": ["photo1.jpg", "photo2.jpg"],
  "created_at": "2024-01-15T10:30:00.000Z"
}
```

### Users

#### GET `/users`
Get list of profiles for browsing.

**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `limit`: Number of profiles (default: 50)
- `offset`: Pagination offset

**Response** (200 OK):
```json
[
  {
    "id": 2,
    "first_name": "Jane",
    "last_name": "Smith",
    "gender": "Female",
    "age": 28,
    "height": "5'4\"",
    "religion": "Hindu",
    "caste": "Kshatriya",
    "avatar": "http://...",
    "city": "Mumbai"
  },
  // ... more profiles
]
```

#### GET `/users/:id`
Get a specific user profile.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
{
  "id": 2,
  "first_name": "Jane",
  "last_name": "Smith",
  "email": "jane@example.com",
  "mobile_no": "9876543211",
  "gender": "Female",
  "dob": "1996-05-20",
  "age": 28,
  "height": "5'4\"",
  "religion": "Hindu",
  "caste": "Kshatriya",
  "sub_caste": null,
  "marital_status": "Never Married",
  "complexion": "Wheatish",
  "mother_tongue": "Gujarati",
  "job": "Software Developer",
  "organization_name": "IT Company",
  "annual_income": "8-10 LPA",
  "food_type": "Vegetarian",
  "manglik": "No",
  "blood_group": "B+",
  "hobbies": "Yoga, Cooking",
  "family_details": "Middle class family",
  "any_requirement": null,
  "avatar": "http://...",
  "gallery_photos": ["photo1.jpg", "photo2.jpg", "photo3.jpg"],
  "created_at": "2024-01-10T08:00:00.000Z"
}
```

#### PATCH `/users/:id`
Update user profile.

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "user": {
    "job": "Senior Developer",
    "hobbies": "Reading, Gaming, Traveling",
    "family_details": "Upper middle class",
    "any_requirement": "Looking for someone with similar interests"
  }
}
```

**Response** (200 OK):
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe",
    // ... updated fields
  }
}
```

#### DELETE `/users/:id`
Delete user account.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
{
  "message": "User deleted successfully"
}
```

#### GET `/users/search?q=query`
Search for users by name or city.

**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `q`: Search query (name or city)

**Response** (200 OK):
```json
[
  {
    "id": 2,
    "first_name": "Jane",
    "last_name": "Smith",
    "gender": "Female",
    "age": 28,
    "height": "5'4\"",
    "religion": "Hindu",
    "caste": "Kshatriya",
    "avatar": "http://...",
    "city": "Mumbai"
  }
]
```

#### GET `/users/suggestions`
Get personalized profile suggestions.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
[
  // Array of user profiles matching preferences
]
```

#### POST `/users/:id/upload_gallery_photo`
Upload a photo to gallery.

**Headers**: 
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body**:
```
photo: [binary file data]
```

**Response** (201 Created):
```json
{
  "message": "Photo uploaded successfully",
  "photo_url": "http://..."
}
```

#### DELETE `/users/:id/delete_gallery_photo`
Delete a gallery photo.

**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `index`: Index of the photo to delete (0-4)

**Response** (200 OK):
```json
{
  "message": "Photo deleted successfully"
}
```

### User Interactions

#### POST `/user_interactions`
Send an interest to another user.

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "user_interaction": {
    "to_user_id": 2,
    "interaction_type": "interested",
    "notes": "I like your profile!"
  }
}
```

**Valid interaction_types**: `interested`, `shortlist`, `noted`, `rejected`

**Response** (201 Created):
```json
{
  "message": "Interaction created successfully",
  "interaction": {
    "id": 1,
    "from_user_id": 1,
    "to_user_id": 2,
    "interaction_type": "interested",
    "status": "pending",
    "notes": "I like your profile!",
    "created_at": "2024-01-15T10:30:00.000Z"
  }
}
```

#### GET `/user_interactions/sent`
Get interests sent by current user.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "interaction_type": "interested",
    "status": "pending",
    "notes": null,
    "user": {
      "id": 2,
      "first_name": "Jane",
      "last_name": "Smith",
      "age": 28,
      "gender": "Female",
      "religion": "Hindu",
      "height": "5'4\"",
      "avatar": "http://..."
    },
    "created_at": "2024-01-15T10:30:00.000Z"
  }
]
```

#### GET `/user_interactions/received`
Get interests received by current user.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
[
  {
    "id": 2,
    "interaction_type": "interested",
    "status": "pending",
    "notes": null,
    "user": {
      "id": 3,
      "first_name": "Rajesh",
      "last_name": "Kumar",
      "age": 32,
      "gender": "Male",
      "religion": "Hindu",
      "height": "5'8\"",
      "avatar": "http://..."
    },
    "created_at": "2024-01-14T15:20:00.000Z"
  }
]
```

#### GET `/user_interactions/shortlist`
Get shortlisted profiles.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
[
  // Array of shortlisted interactions
]
```

#### POST `/user_interactions/:id/accept`
Accept a received interest.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
{
  "message": "Interest accepted",
  "interaction": {
    "id": 2,
    "from_user_id": 3,
    "to_user_id": 1,
    "interaction_type": "interested",
    "status": "accepted",
    "created_at": "2024-01-14T15:20:00.000Z"
  }
}
```

#### POST `/user_interactions/:id/decline`
Decline a received interest.

**Headers**: `Authorization: Bearer {token}`

**Response** (200 OK):
```json
{
  "message": "Interest declined",
  "interaction": {
    "id": 2,
    "from_user_id": 3,
    "to_user_id": 1,
    "interaction_type": "interested",
    "status": "declined",
    "created_at": "2024-01-14T15:20:00.000Z"
  }
}
```

## Error Handling

### Common HTTP Status Codes

- `200 OK` - Successful GET/PATCH request
- `201 Created` - Successful POST request creating a resource
- `400 Bad Request` - Malformed request
- `401 Unauthorized` - Missing or invalid authentication token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

### Error Response Examples

**Validation Error** (422):
```json
{
  "errors": [
    "Email has already been taken",
    "Mobile number must be 10 digits"
  ]
}
```

**Unauthorized** (401):
```json
{
  "error": "Unauthorized"
}
```

## Rate Limiting

Currently no rate limiting is implemented. For production, consider implementing:
- 100 requests per minute per IP
- 1000 requests per hour per user

## Best Practices

1. **Always include the Authorization header** for authenticated endpoints
2. **Validate input data** on the client before sending
3. **Handle errors gracefully** with appropriate user feedback
4. **Cache responses** when appropriate to reduce API calls
5. **Use pagination** for large result sets
6. **Set reasonable timeouts** (e.g., 30 seconds)
7. **Log errors** for debugging and monitoring

## CORS Configuration

The API is configured to accept requests from all origins during development. For production, update the CORS configuration in `config/initializers/cors.rb`:

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'yourdomain.com', 'app.yourdomain.com'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete]
  end
end
```

## Deployment

Before deploying to production:

1. Update `CORS` origins to match your domain
2. Generate secure secret tokens for JWT (if using JWT)
3. Enable HTTPS
4. Set up SSL certificates
5. Configure database backups
6. Set up monitoring and logging
7. Test all endpoints thoroughly

## Support

For issues or questions about the API, please contact the development team.
