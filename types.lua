local types = {}

function types.nonNull(kind)
  assert(kind, 'Must provide a type')

  return {
    __type = 'NonNull',
    ofType = kind
  }
end

function types.scalar(config)
  assert(type(config.name) == 'string', 'type name must be provided as a string')
  assert(type(config.serialize) == 'function', 'serialize must be a function')
  if config.parseValue or config.parseLiteral then
    assert(
      type(config.parseValue) == 'function' and type(config.parseLiteral) == 'function',
      'must provide both parseValue and parseLiteral to scalar type'
    )
  end

  local instance = {
    __type = 'Scalar',
    name = config.name,
    description = config.description,
    serialize = config.serialize,
    parseValue = config.parseValue,
    parseLiteral = config.parseLiteral
  }

  instance.nonNull = types.nonNull(instance)

  return instance
end

function types.object(config)
  assert(type(config.name) == 'string', 'type name must be provided as a string')
  if config.isTypeOf then
    assert(type(config.isTypeOf) == 'function', 'must provide isTypeOf as a function')
  end
  assert(type(config.fields) == 'table', 'fields table must be provided')

  local fields = {}
  for fieldName, field in pairs(config.fields) do
    field = field.__type and { kind = field } or field
    fields[fieldName] = {
      name = fieldName,
      kind = field.kind,
      args = field.args or {}
    }
  end

  local instance = {
    __type = 'Object',
    name = config.name,
    isTypeOf = config.isTypeOf,
    fields = fields
  }

  instance.nonNull = types.nonNull(instance)

  return instance
end

function types.interface(config)
  assert(type(config.name) == 'string', 'type name must be provided as a string')
  assert(type(config.fields) == 'table', 'fields table must be provided')
  if config.resolveType then
    assert(type(config.resolveType) == 'function', 'must provide resolveType as a function')
  end

  local instance = {
    __type = 'Interface',
    name = config.name,
    description = config.description,
    fields = config.fields,
    resolveType = config.resolveType
  }

  instance.nonNull = types.nonNull(instance)

  return instance
end

function types.enum(config)
  assert(type(config.name) == 'string', 'type name must be provided as a string')
  assert(type(config.values) == 'table', 'values table must be provided')

  local instance = {
    __type = 'Enum',
    name = config.name,
    description = config.description,
    values = config.values
  }

  instance.nonNull = types.nonNull(instance)

  return instance
end

function types.union(config)
  assert(type(config.name) == 'string', 'type name must be provided as a string')
  assert(type(config.types) == 'table', 'types table must be provided')

  local instance = {
    __type = 'Union',
    name = config.name,
    types = config.types
  }

  instance.nonNull = types.nonNull(instance)

  return instance
end

local coerceInt = function(value)
  value = tonumber(value)

  if not value then return end

  if value == value and value < 2 ^ 32 and value >= -2 ^ 32 then
    return value < 0 and math.ceil(value) or math.floor(value)
  end
end

types.int = types.scalar({
  name = 'Int',
  serialize = coerceInt,
  parseValue = coerceInt,
  parseLiteral = function(node)
    if node.kind == 'int' then
      return coerceInt(node.value)
    end
  end
})

types.float = types.scalar({
  name = 'Float',
  serialize = tonumber,
  parseValue = tonumber,
  parseLiteral = function(node)
    if node.kind == 'float' or node.kind == 'int' then
      return tonumber(node.value)
    end
  end
})

types.string = types.scalar({
  name = 'String',
  serialize = tostring,
  parseValue = tostring,
  parseLiteral = function(node)
    if node.kind == 'string' then
      return node.value
    end
  end
})

local function toboolean(x)
  return x and true or false
end

types.boolean = types.scalar({
  name = 'Boolean',
  serialize = toboolean,
  parseValue = toboolean,
  parseLiteral = function(node)
    return node.kind == 'boolean' and node.value or nil
  end
})

types.id = types.scalar({
  name = 'ID',
  serialize = tostring,
  parseValue = tostring,
  parseLiteral = function(node)
    return node.kind == 'string' or node.kind == 'int' and node.value or nil
  end
})

return types
