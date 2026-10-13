package com.fieldnotes.user.service;

import com.fieldnotes.exception.InvalidCredentialsException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;
import java.util.Set;

/**
 * Verifies a Google ID token (sent by the app after "Continue with Google").
 * Google's tokeninfo endpoint checks the signature and expiry for us; we check
 * that the token was issued for OUR client id and that the e-mail is verified.
 *
 * Needs GOOGLE_CLIENT_ID = the "Web application" OAuth client id (same value the app
 * passes as GOOGLE_SERVER_CLIENT_ID).
 */
@Service
public class GoogleAuthService {

    private static final Set<String> ISSUERS =
        Set.of("accounts.google.com", "https://accounts.google.com");

    private final RestClient restClient = RestClient.create();
    private final String clientId;

    public GoogleAuthService(@Value("${app.google.client-id:}") String clientId) {
        this.clientId = clientId;
    }

    public record GoogleProfile(String email, String name) {
    }

    public GoogleProfile verify(String idToken) {
        if (clientId == null || clientId.isBlank()) {
            throw new IllegalArgumentException(
                "Google login is not configured on the server (GOOGLE_CLIENT_ID)"
            );
        }

        Map<String, Object> info;
        try {
            info = restClient.get()
                .uri("https://oauth2.googleapis.com/tokeninfo?id_token={token}", idToken)
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {
                });
        } catch (RestClientException e) {
            throw new InvalidCredentialsException("Invalid Google token");
        }

        if (info == null
            || !clientId.equals(String.valueOf(info.get("aud")))
            || !ISSUERS.contains(String.valueOf(info.get("iss")))
            || !"true".equals(String.valueOf(info.get("email_verified")))
            || info.get("email") == null) {
            throw new InvalidCredentialsException("Invalid Google token");
        }

        String email = String.valueOf(info.get("email"));
        Object name = info.get("name");
        return new GoogleProfile(
            email,
            name == null || String.valueOf(name).isBlank()
                ? email.substring(0, email.indexOf('@'))
                : String.valueOf(name)
        );
    }
}
