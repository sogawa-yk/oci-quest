package com.mushop.catalogue.service;

import com.mushop.catalogue.model.Product;
import com.mushop.catalogue.repository.CategoryRepository;
import com.mushop.catalogue.repository.ProductRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class CatalogueServiceImpl implements CatalogueService {
    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;

    public CatalogueServiceImpl(ProductRepository productRepository, CategoryRepository categoryRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
    }

    @Override
    public List<Product> list(List<String> categories, String order, int pageNum, int pageSize) {
        if (pageNum == 0 || pageSize == 0) {
            return Collections.emptyList();
        }

        List<Product> products;
        if (categories == null || categories.isEmpty()) {
            products = productRepository.findAll();
        } else {
            products = productRepository.findByCategoryNames(categories);
        }

        // Apply pagination
        int start = (pageNum * pageSize) - pageSize;
        if (start >= products.size()) {
            return Collections.emptyList();
        }
        int end = Math.min((pageNum * pageSize), products.size());
        
        return products.subList(start, end);
    }

    @Override
    public long count(List<String> categories) {
        if (categories == null || categories.isEmpty()) {
            return productRepository.count();
        }
        return productRepository.countByCategoryNames(categories);
    }

    @Override
    public Product get(String id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found"));
    }

    @Override
    public List<String> categories() {
        return categoryRepository.findAll().stream()
                .map(category -> category.getName())
                .collect(Collectors.toList());
    }

    @Override
    public List<Health> health() {
        String timestamp = LocalDateTime.now().toString();
        List<Health> health = List.of(
            new Health("catalogue", "OK", timestamp),
            new Health("catalogue-db", "OK", timestamp)
        );
        return health;
    }
}
