package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.services.IDepartmentService;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DepartmentControllerTest {

    @Test
    void getAllDepartment_shouldReturnListFromService() {
        IDepartmentService service = mock(IDepartmentService.class);
        when(service.getAllDepartments()).thenReturn(List.of(new Department(), new Department()));

        DepartmentController controller = new DepartmentController(service);

        List<Department> result = controller.getAllDepartment();

        assertEquals(2, result.size());
        verify(service).getAllDepartments();
    }

    @Test
    void getDepartment_shouldReturnDepartmentFromService() {
        IDepartmentService service = mock(IDepartmentService.class);
        Department dep = new Department();
        dep.setIdDepartment(1L);

        when(service.getDepartmentById(1L)).thenReturn(dep);

        DepartmentController controller = new DepartmentController(service);

        Department result = controller.getDepartment(1L);

        assertNotNull(result);
        assertEquals(1L, result.getIdDepartment());
        verify(service).getDepartmentById(1L);
    }

    @Test
    void createDepartment_shouldCallServiceAndReturnResult() {
        IDepartmentService service = mock(IDepartmentService.class);
        Department dep = new Department();
        dep.setName("Informatique");

        when(service.saveDepartment(dep)).thenReturn(dep);

        DepartmentController controller = new DepartmentController(service);

        Department result = controller.createDepartment(dep);

        assertEquals("Informatique", result.getName());
        verify(service).saveDepartment(dep);
    }

    @Test
    void updateDepartment_shouldCallServiceAndReturnResult() {
        IDepartmentService service = mock(IDepartmentService.class);
        Department dep = new Department();
        dep.setIdDepartment(5L);

        when(service.saveDepartment(dep)).thenReturn(dep);

        DepartmentController controller = new DepartmentController(service);

        Department result = controller.updateDepartment(dep);

        assertEquals(5L, result.getIdDepartment());
        verify(service).saveDepartment(dep);
    }

    @Test
    void deleteDepartment_shouldCallServiceDelete() {
        IDepartmentService service = mock(IDepartmentService.class);

        DepartmentController controller = new DepartmentController(service);

        controller.deleteDepartment(10L);

        verify(service).deleteDepartment(10L);
    }
}
