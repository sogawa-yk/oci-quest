package com.mushop.catalogue.service;

import com.mushop.catalogue.model.Product;

import java.util.List;

public interface CatalogueService {
    List<Product> list(List<String> categories, String order, int pageNum, int pageSize);
    
    long count(List<String> categories);
    
    Product get(String id);
    
    List<String> categories();
    
    List<Health> health();
    
    record Health(String service, String status, String time) {}
}
