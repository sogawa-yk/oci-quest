package com.mushop.catalogue.controller;

import com.mushop.catalogue.model.Product;
import com.mushop.catalogue.service.CatalogueService;
import com.mushop.catalogue.service.CatalogueService.Health;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/")
public class CatalogueController {
    private final CatalogueService catalogueService;

    public CatalogueController(CatalogueService catalogueService) {
        this.catalogueService = catalogueService;
    }

    @GetMapping("/catalogue")
    public List<Product> list(
            @RequestParam(required = false) List<String> categories,
            @RequestParam(required = false) String order,
            @RequestParam(defaultValue = "1") int pageNum,
            @RequestParam(defaultValue = "10") int pageSize) {
        return catalogueService.list(categories, order, pageNum, pageSize);
    }

    @GetMapping("/catalogue/size")
    public long count(@RequestParam(required = false) List<String> categories) {
        return catalogueService.count(categories);
    }

    @GetMapping("/catalogue/{id}")
    public Product get(@PathVariable String id) {
        return catalogueService.get(id);
    }

    @GetMapping("/categories")
    public List<String> categories() {
        return catalogueService.categories();
    }

    @GetMapping("/health")
    public List<Health> health() {
        return catalogueService.health();
    }
}
