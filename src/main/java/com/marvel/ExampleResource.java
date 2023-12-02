package com.marvel;

import com.marvel.entity.ExclusionRepository;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.*;

@Path("/hello")
public class ExampleResource {
    @Inject
    ExclusionRepository repo;
    static final Region REGION = Region.EU_CENTRAL_1;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response getHeroDeck(
            @Parameter(example = "Deadpool") @QueryParam("hero") @NotNull String hero
    ) {
        repo.getHeroDeck("Deadpool");
        /*S3Client s3Client = S3Client.builder()
                .region(REGION).build();

        try {
            HeadObjectRequest objectRequest = HeadObjectRequest.builder()
                    .key("44001a.png")
                    .bucket("card-images-marvel-champions")
                    .build();

            HeadObjectResponse objectHead = s3Client.headObject(objectRequest);
            String type = objectHead.contentType();
            System.out.println("The object content type is " + type);

            s3Client.getObject(
                    GetObjectRequest.builder()
                            .key("44001a.png")
                            .bucket("card-images-marvel-champions")
                            .build());

            ResponseBytes<GetObjectResponse> objectBytes = s3Client.getObjectAsBytes(
                    GetObjectRequest.builder()
                    .key("44001a.png")
                    .bucket("card-images-marvel-champions")
                    .build());

            byte[] data = objectBytes.asByteArray();

            // Write the data to a local file.
            File myFile = new File("Desktop" );
            OutputStream os = new FileOutputStream(myFile);
            os.write(data);
            System.out.println("Successfully obtained bytes from an S3 object");
            os.close();

        } catch (S3Exception e) {
            System.err.println(e.awsErrorDetails().errorMessage());
            System.exit(1);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }*/

        return Response.ok().build();
    }
}
