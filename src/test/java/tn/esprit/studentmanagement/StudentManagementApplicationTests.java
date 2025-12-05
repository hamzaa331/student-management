package tn.esprit.studentmanagement;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")   // <<--- AJOUTE ÇA
class StudentManagementApplicationTests {

    @Test
    void contextLoads() {
    }

    @Test
    void mainMethodRuns() {
        // Appelle la méthode main pour couvrir StudentManagementApplication.main()
        StudentManagementApplication.main(new String[]{});
    }
    
}
