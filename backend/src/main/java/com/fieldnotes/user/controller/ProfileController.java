package com.fieldnotes.user.controller;

import com.fieldnotes.user.dto.ChangePasswordRequest;
import com.fieldnotes.user.dto.MessageResponse;
import com.fieldnotes.user.dto.UpdateProfileRequest;
import com.fieldnotes.user.dto.UserResponse;
import com.fieldnotes.user.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;


@RestController
@RequestMapping("/api/users/me")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        return ResponseEntity.ok(profileService.getProfile(userId(authentication)));
    }

    @PutMapping
    public ResponseEntity<UserResponse> update(
        Authentication authentication,
        @Valid @RequestBody UpdateProfileRequest request
    ) {
        return ResponseEntity.ok(
            profileService.updateName(userId(authentication), request.name())
        );
    }

    @PostMapping("/change-password")
    public ResponseEntity<MessageResponse> changePassword(
        Authentication authentication,
        @Valid @RequestBody ChangePasswordRequest request
    ) {
        profileService.changePassword(userId(authentication), request);
        return ResponseEntity.ok(new MessageResponse("Password changed"));
    }

    private UUID userId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
