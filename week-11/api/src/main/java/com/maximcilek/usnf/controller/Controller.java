package com.maximcilek.usnf.controller;

import om.maximcilek.usnf.dto.NameResponse;
import om.maximcilek.usnf.service.NameService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/nameinfo")
public class NameController {

    private final NameService service;

    public NameController(NameService service) {
        this.service = service;
    }

    @GetMapping
    public NameResponse getName(@RequestParam String name) {
        return service.getNameInfo(name);
    }
}