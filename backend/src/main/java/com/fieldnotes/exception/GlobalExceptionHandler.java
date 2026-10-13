package com.fieldnotes.exception;

import com.fieldnotes.common.response.ApiError;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(
        ResourceNotFoundException exception,
        HttpServletRequest request
    ) {
        return buildError(
            HttpStatus.NOT_FOUND,
            exception.getMessage(),
            request.getRequestURI(),
            Map.of()
        );
    }

    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<ApiError> handleInvalidCredentials(
        InvalidCredentialsException exception,
        HttpServletRequest request
    ) {
        return buildError(
            HttpStatus.UNAUTHORIZED,
            exception.getMessage(),
            request.getRequestURI(),
            Map.of()
        );
    }

    @ExceptionHandler(DuplicateResourceException.class)
    public ResponseEntity<ApiError> handleDuplicate(
        DuplicateResourceException exception,
        HttpServletRequest request
    ) {
        return buildError(
            HttpStatus.CONFLICT,
            exception.getMessage(),
            request.getRequestURI(),
            Map.of()
        );
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegalArgument(
        IllegalArgumentException exception,
        HttpServletRequest request
    ) {
        return buildError(
            HttpStatus.BAD_REQUEST,
            exception.getMessage(),
            request.getRequestURI(),
            Map.of()
        );
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> handleUnreadable(
        HttpMessageNotReadableException exception,
        HttpServletRequest request
    ) {
        return buildError(
            HttpStatus.BAD_REQUEST,
            "Malformed request body",
            request.getRequestURI(),
            Map.of()
        );
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiError> handleTooLarge(
        MaxUploadSizeExceededException exception,
        HttpServletRequest request
    ) {
        return buildError(
            HttpStatus.PAYLOAD_TOO_LARGE,
            "File is too large (max 10 MB)",
            request.getRequestURI(),
            Map.of()
        );
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(
        MethodArgumentNotValidException exception,
        HttpServletRequest request
    ) {
        Map<String, String> validationErrors = new LinkedHashMap<>();

        exception.getBindingResult().getFieldErrors().forEach(error ->
            validationErrors.put(error.getField(), error.getDefaultMessage())
        );

        return buildError(
            HttpStatus.BAD_REQUEST,
            "Validation failed",
            request.getRequestURI(),
            validationErrors
        );
    }

    private ResponseEntity<ApiError> buildError(
        HttpStatus status,
        String message,
        String path,
        Map<String, String> validationErrors
    ) {
        ApiError error = new ApiError(
            Instant.now(),
            status.value(),
            status.getReasonPhrase(),
            message,
            path,
            validationErrors
        );

        return ResponseEntity.status(status).body(error);
    }
}
