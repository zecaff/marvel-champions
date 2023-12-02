package com.marvel.entity;

import lombok.Getter;
import lombok.Setter;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.*;

import java.util.List;

@DynamoDbBean
public class Card {

    @Getter(onMethod_ = {
            @DynamoDbPartitionKey,
            @DynamoDbAttribute("ID")
    })
    @Setter
    private String ID;
    @Getter(onMethod_ = {
            @DynamoDbSortKey,
            @DynamoDbAttribute("Title"),
            @DynamoDbSecondaryPartitionKey(indexNames = {"CardNameIndex"})
    })
    @Setter
    private String Title;
    @Getter(onMethod_ = {
            @DynamoDbSecondarySortKey(indexNames = {"CardNameIndex"}),
            @DynamoDbAttribute("Aspect")
    })
    @Setter
    private String Aspect;
    @Getter(onMethod_ = {
            @DynamoDbAttribute("FrontImageUrl")
    })
    @Setter
    private String frontImageUrl;
    @Getter(onMethod_ = {
            @DynamoDbAttribute("Hero")
    })
    @Setter
    private String Hero;
    @Getter(onMethod_ = {
            @DynamoDbAttribute("Effect")
    })
    @Setter
    private String effect;
    @Setter
    @Getter(onMethod_ = {
            @DynamoDbAttribute("Traits")
    })
    private List<String> traits;

}