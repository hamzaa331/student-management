package tn.esprit.studentmanagement;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class StudentManagementApplicationTests {

    @Test
    void contextLoads() {
        // Test qui vérifie que le contexte démarre correctement
    }

    @Test
    void mainMethodRuns() {
        // Appelle la méthode main pour couvrir 100% du fichier
        StudentManagementApplication.main(new String[] {});
    }
}
