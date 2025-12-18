package tn.esprit.studentmanagement;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

/**
 * Test class to verify the main method can be executed.
 * This ensures code coverage for the main method.
 */
class StudentManagementApplicationMainTest {

    @Test
    void testMainMethod() {
        // Force Spring Boot to use the in‑memory H2 "test" profile instead of MySQL
        System.setProperty("spring.profiles.active", "test");

        // Prevent the application from actually starting a web server
        System.setProperty("spring.main.web-application-type", "none");

        // Call the main method and assert it doesn't throw an exception
        assertDoesNotThrow(() -> StudentManagementApplication.main(new String[]{}));

        // Clean up
        System.clearProperty("spring.profiles.active");
        System.clearProperty("spring.main.web-application-type");
    }
}
