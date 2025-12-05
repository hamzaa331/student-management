package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.services.IStudentService;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class StudentControllerTest {

    @Test
    void getAllStudents_shouldReturnListFromService() {
        IStudentService service = mock(IStudentService.class);
        when(service.getAllStudents()).thenReturn(List.of(new Student(), new Student(), new Student()));

        StudentController controller = new StudentController(service);

        List<Student> result = controller.getAllStudents();

        assertEquals(3, result.size());
        verify(service).getAllStudents();
    }

    @Test
    void getStudent_shouldReturnOneFromService() {
        IStudentService service = mock(IStudentService.class);
        Student s = new Student();
        s.setIdStudent(1L);

        when(service.getStudentById(1L)).thenReturn(s);

        StudentController controller = new StudentController(service);

        Student result = controller.getStudent(1L);

        assertNotNull(result);
        assertEquals(1L, result.getIdStudent());
        verify(service).getStudentById(1L);
    }

    @Test
    void createStudent_shouldCallServiceAndReturnResult() {
        IStudentService service = mock(IStudentService.class);
        Student s = new Student();
        s.setFirstName("Hamza");

        when(service.saveStudent(s)).thenReturn(s);

        StudentController controller = new StudentController(service);

        Student result = controller.createStudent(s);

        assertEquals("Hamza", result.getFirstName());
        verify(service).saveStudent(s);
    }

    @Test
    void updateStudent_shouldCallServiceAndReturnResult() {
        IStudentService service = mock(IStudentService.class);
        Student s = new Student();
        s.setIdStudent(5L);

        when(service.saveStudent(s)).thenReturn(s);

        StudentController controller = new StudentController(service);

        Student result = controller.updateStudent(s);

        assertEquals(5L, result.getIdStudent());
        verify(service).saveStudent(s);
    }

    @Test
    void deleteStudent_shouldCallServiceDelete() {
        IStudentService service = mock(IStudentService.class);

        StudentController controller = new StudentController(service);

        controller.deleteStudent(9L);

        verify(service).deleteStudent(9L);
    }
}
