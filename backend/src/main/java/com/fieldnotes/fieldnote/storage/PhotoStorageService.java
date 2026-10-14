package com.fieldnotes.fieldnote.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;


@Service
public class PhotoStorageService {

    private static final Map<String, String> EXTENSIONS = Map.of(
        "image/jpeg", ".jpg",
        "image/png", ".png",
        "image/webp", ".webp",
        "image/heic", ".heic"
    );

    private final Path root;

    public PhotoStorageService(@Value("${app.upload-dir:uploads}") String uploadDir) {
        this.root = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot create upload directory: " + root, e);
        }
    }

    public String store(UUID noteId, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Photo file is empty");
        }
        String contentType = file.getContentType();
        String extension = contentType == null ? null : EXTENSIONS.get(contentType.toLowerCase());
        if (extension == null) {
            throw new IllegalArgumentException("Only JPEG, PNG, WEBP or HEIC images are allowed");
        }

        String fileName = noteId + "-" + UUID.randomUUID() + extension;
        try (InputStream in = file.getInputStream()) {
            Files.copy(in, root.resolve(fileName), StandardCopyOption.REPLACE_EXISTING);
        }
        return fileName;
    }

    public Resource load(String fileName) {
        Path path = root.resolve(fileName).normalize();
        if (!path.startsWith(root) || !Files.exists(path)) {
            return null;
        }
        return new FileSystemResource(path);
    }

    public void delete(String fileName) {
        if (fileName == null) {
            return;
        }
        try {
            Path path = root.resolve(fileName).normalize();
            if (path.startsWith(root)) {
                Files.deleteIfExists(path);
            }
        } catch (IOException ignored) {
            // best effort
        }
    }

    public String contentTypeOf(String fileName) {
        String name = fileName.toLowerCase();
        if (name.endsWith(".png")) return "image/png";
        if (name.endsWith(".webp")) return "image/webp";
        if (name.endsWith(".heic")) return "image/heic";
        return "image/jpeg";
    }
}
