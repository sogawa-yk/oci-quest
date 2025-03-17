package com.mushop.catalogue.repository;

import com.mushop.catalogue.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, String> {
    @Query("SELECT DISTINCT p FROM Product p JOIN p.categories c WHERE c.name IN :categories")
    List<Product> findByCategoryNames(@Param("categories") List<String> categories);

    @Query("SELECT COUNT(DISTINCT p) FROM Product p JOIN p.categories c WHERE c.name IN :categories")
    long countByCategoryNames(@Param("categories") List<String> categories);
}
