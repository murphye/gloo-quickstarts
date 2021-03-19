TODO

This Quickstart will focus on end-to-end use of an OpenAPI spec to generate a Spring Boot application API. Additionally, the same OpenAPI spec will be used for a Gloo Portal APIProduct.

npm install @openapitools/openapi-generator-cli -g

https://raw.githubusercontent.com/openapitools/openapi-generator/master/modules/openapi-generator/src/test/resources/3_0/petstore.yaml

openapi-generator-cli generate -i petstore.yaml -g ruby -o /tmp/test/

openapi-generator-cli author template -g java --library webclient


<dependency>
    <groupId>io.swagger.core.v3</groupId>
    <artifactId>swagger-annotations</artifactId>
</dependency>
<dependency>
    <groupId>io.swagger.parser.v3</groupId>
    <artifactId>swagger-parser</artifactId>
</dependency>


<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>wagon-maven-plugin</artifactId>
  <version>1.0</version>
  <executions>
    <execution>
      <phase>validate</phase>
      <goals><goal>download-single</goal></goals>
      <configuration>
        <url>http://www.mojohaus.org/wagon-maven-plugin</url>
        <fromFile>download-single-mojo.html</fromFile>
        <toFile>[my dir]/mojo-help.html</toFile>
      </configuration>
    </execution>
  </executions>
</plugin>


<plugin>
    <groupId>org.openapitools</groupId>
    <artifactId>openapi-generator-maven-plugin</artifactId>
    <version>5.0.0</version>
    <executions>
        <execution>
            <goals>
                <goal>generate</goal>
            </goals>
            <configuration>
                <inputSpec>${project.basedir}/src/main/resources/api.yaml</inputSpec>
                <generatorName>java</generatorName>
                <configOptions>
                   <sourceFolder>src/gen/java/main</sourceFolder>
                </configOptions>
            </configuration>
        </execution>
    </executions>
</plugin>