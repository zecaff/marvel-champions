package com.marvel.entity;

import jakarta.enterprise.context.ApplicationScoped;
import software.amazon.awssdk.core.pagination.sync.SdkIterable;
import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.enhanced.dynamodb.model.*;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.ScanRequest;

import java.util.Map;

@ApplicationScoped
public class ExclusionRepository {

    //global indexes allow faster searches (we dont need to use scan when we want to query by non
    //partition key values) however if we want all attributes thats an extra storage cost and write cost
    //because aws keeps an extra table
    static final TableSchema<Card> CUSTOMER_TABLE_SCHEMA = TableSchema.fromClass(Card.class);


    public void getHeroDeck(String heroName){
        DynamoDbEnhancedClient dbClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(
                        // Configure an instance of the standard client.
                        DynamoDbClient.builder()
                                .region(Region.EU_CENTRAL_1)
                                .build())
                .build();
        DynamoDbTable<Card> cardTable =
                dbClient.table("CardTable", CUSTOMER_TABLE_SCHEMA);
        ScanEnhancedRequest request =
                ScanEnhancedRequest
                        .builder()
                        .filterExpression(
                                Expression.builder()
                                        .expression("Hero = :hero")
                        .expressionValues(
                                Map.of(":hero", AttributeValue.builder().s(heroName).build()) // Using Java 9+ Map.of
                        )
                        .build()
                        ).build();

        PageIterable<Card> pagedResults = cardTable.scan(request);
        pagedResults.items().stream().forEach(p -> System.out.println(p.getTraits()));
    }

    public void read() {
        DynamoDbEnhancedClient dbClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(
                        // Configure an instance of the standard client.
                        DynamoDbClient.builder()
                                .region(Region.EU_CENTRAL_1)
                                .build())
                .build();
        DynamoDbTable<Card> cardTable =
                dbClient.table("CardTable", CUSTOMER_TABLE_SCHEMA);

        DynamoDbIndex<Card> index = cardTable.index("CardNameIndex");
        QueryConditional queryConditional = QueryConditional.keyEqualTo(
                Key.builder().partitionValue("Deadpool").sortValue("Hero").build()
        );

         /*Card customer = cardTable.getItem(Key.builder().partitionValue("a63d1fd9-4b5d-4f60-a7a0-1a8bb734bef2")
                .sortValue("Deadpool").build());

        System.out.println(customer.getTraits());*/

        /*PageIterable<Card> pagedResults = cardTable.scan();
        System.out.println(pagedResults.items().stream().count());
        pagedResults.items().stream().forEach(p -> System.out.println(p.getAspect()));*/

        final SdkIterable<Page<Card>> pagedResult = index.query(QueryEnhancedRequest.builder()
                .queryConditional(queryConditional)
                .build());
        pagedResult.forEach(page -> page.items()
                .forEach(mt -> {
                    System.out.println(mt.getTraits());
                }));
    }

}
