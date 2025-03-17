package com.mushop.catalogue.model;

import jakarta.persistence.*;
import lombok.Data;

import java.util.List;
import java.util.Set;

@Data
@Entity
@Table(name = "PRODUCTS")
public class Product {
    @Id
    @Column(name = "SKU")
    private String id;

    @Column(name = "BRAND")
    private String brand;

    @Column(name = "TITLE")
    private String title;

    @Column(name = "DESCRIPTION")
    private String description;

    @Column(name = "WEIGHT")
    private String weight;

    @Column(name = "PRODUCT_SIZE")
    private String productSize;

    @Column(name = "COLORS")
    private String colors;

    @Column(name = "QTY")
    private Integer qty;

    @Column(name = "PRICE")
    private Float price;

    @Column(name = "IMAGE_URL_1")
    private String imageUrl1;

    @Column(name = "IMAGE_URL_2")
    private String imageUrl2;

    @ManyToMany
    @JoinTable(
        name = "PRODUCT_CATEGORY",
        joinColumns = @JoinColumn(name = "SKU"),
        inverseJoinColumns = @JoinColumn(name = "CATEGORY_ID")
    )
    private Set<Category> categories;

    @Transient
    private List<String> imageUrl;

    public List<String> getImageUrl() {
        return List.of(imageUrl1, imageUrl2);
    }
}
