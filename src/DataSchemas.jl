
module DataSchemas
export Column, Schema, SchemaValidationError, ValidationConfig, validate

import DataFrames

struct Column{T}
end

abstract type Schema end

struct SchemaValidationError <: Exception
    msg::String
end

struct ValidationConfig
    allow_extra_columns::Val
end
ValidationConfig(; allow_extra_columns::Bool) = ValidationConfig(Val(allow_extra_columns))

function validate(
    schema::Type{<:Schema},
    config::ValidationConfig,
    data_frame::DataFrames.DataFrame,
)
    check_required_columns_exist(schema, data_frame)
    for (column_name, columns_values) in pairs(eachcol(data_frame))
        check_column(schema, config, column_name, columns_values)
    end
end

function check_required_columns_exist(
    schema::Type{<:Schema},
    data_frame::DataFrames.DataFrame,
)
    for (field_name, field_type) in zip(fieldnames(schema), schema.types)
        if field_type <: Column && !(field_name in keys(eachcol(data_frame)))
            throw(SchemaValidationError("Could not find column $field_name from schema $schema in dataframe $(first(data_frame))."))
        end
    end

end

function check_column(
    schema::Type{<:Schema},
    config::ValidationConfig,
    column_name::Symbol,
    column_contents,
)
    check_column_in_schema(schema, column_name, config.allow_extra_columns)
end

function check_column_in_schema(schema::Type{<:Schema}, column_name::Symbol, allow_extra_columns::Val{true})
    # No-op
end

function check_column_in_schema(schema::Type{<:Schema}, column_name::Symbol, allow_extra_columns::Val{false})
    if !(column_name in fieldnames(schema))
        throw(SchemaValidationError("""
        Column $column_name not found in schema $schema.\
        Add $column_name to the schema or set 'allow_extra_columns'=true."""
        ))
    end
end


end # DataSchemas