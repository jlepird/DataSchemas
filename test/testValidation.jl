using DataSchemas
using Test
using RDatasets

iris = dataset("datasets", "iris")

struct IrisSchema <: Schema
    SepalLength::Column{AbstractFloat}
    SepalWidth::Column{AbstractFloat}
    PetalLength::Column{AbstractFloat}
    PetalWidth::Column{AbstractFloat}
    Species::Column{String}
end

@testset "column existance" begin
    strict_schema_config = ValidationConfig(allow_extra_columns=false)
    lax_schema_config = ValidationConfig(allow_extra_columns=true)

    @testset "Regardless of config, pass when schema exactly matches." begin
        validate(IrisSchema, strict_schema_config, iris)
        validate(IrisSchema, lax_schema_config, iris)
    end

    @testset "When extra column present, pass only if `allow_extra_columns`" begin
        iris_copy = deepcopy(iris)
        iris_copy[!, :SomeOtherColumn] .= "foo"
        validate(IrisSchema, lax_schema_config, iris_copy)
        @test_throws SchemaValidationError validate(IrisSchema, strict_schema_config, iris_copy)
    end

    @testset "When required columns missing, always fail." begin
        iris_copy = deepcopy(iris)
        select!(iris_copy, Not(:Species))
        @test_throws SchemaValidationError validate(IrisSchema, strict_schema_config, iris_copy)
        @test_throws SchemaValidationError validate(IrisSchema, lax_schema_config, iris_copy)
    end
end
