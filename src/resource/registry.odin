package resource

/**
    Originally this was supposed to use a map[string]T, but I decided to go with cstring in this case, since it will almost exclusively handle raylib stuff
**/

@(private)
Registry :: struct($T: typeid) {
    items: map[cstring]T,
    deletionHandler: proc(^T),
    isInitialized: bool
}

/*
Will initialize the provided registry with a cap of "cap" items
*/
@(private)
registry_create :: proc(
    self: ^Registry($T),
    deletionHandler: proc(^T),
    cap: int = 200, 
    loc := #caller_location
) -> Error {
    if self == nil do return RegistryError.Registry_Cannot_Be_Nil
    if cap <= 0 do return RegistryError.RegistryCap_Should_Be_Greater_Than_Zero

    self.items = make_map_cap(map[cstring]T, cap, context.allocator, loc) or_return
    self.deletionHandler = deletionHandler
    self.isInitialized = true
    return nil
}

/*
Will destroy the provided registry after calling the DeletinHandler for all its contents
*/
@(private)
registry_destroy :: proc(
    self: ^Registry($T),
    loc := #caller_location
) -> Error {
    if self == nil do return RegistryError.Registry_Cannot_Be_Nil
    if !self.isInitialized do return RegistryError.Registry_Not_Initialized

    for key, &entry in self.items {
        self.deletionHandler(&entry)
    }

    delete_map(self.items, loc) or_return
    return nil
}

/*
Will put the provided item into the registry with the provided identifier

Will throw an error when identifier already exists...
Duplication safety is for the user to consider
*/
@(private)
registry_put :: proc(
    self: ^Registry($T),
    key: cstring,
    value: T
) -> (^T, Error) {
    if self == nil do return nil, RegistryError.Registry_Cannot_Be_Nil
    if !self.isInitialized do return nil, RegistryError.Registry_Not_Initialized
    if key in self.items do return nil, RegistryError.Entry_Already_Exists

    self.items[key] = value
    return &self.items[key], nil
}

/*
Returns a pointer reference to the requested entry, should it exist.
If it doesnt this function will throw an error
*/
@(private)
registry_get :: proc(
    self: ^Registry($T),
    key: cstring
) -> (^T, Error) {
    if self == nil do return nil, RegistryError.Registry_Cannot_Be_Nil
    if !self.isInitialized do return nil, RegistryError.Registry_Not_Initialized
    if !(key in self.items) do return nil, RegistryError.Entry_Does_Not_Exist

    return &self.items[key], nil
}

/*
Will return true when the requested entry is present inside the registry
*/
@(private)
registry_has :: proc(
    self: ^Registry($T),
    key: cstring
) -> (bool, Error) {
    if self == nil do return false, RegistryError.Registry_Cannot_Be_Nil
    if !self.isInitialized do return false, RegistryError.Registry_Not_Initialized

    return key in self.items, nil
}

RegistryError :: enum {
    None = 0,
    Registry_Cannot_Be_Nil,
    Registry_Not_Initialized,
    RegistryCap_Should_Be_Greater_Than_Zero,
    Entry_Already_Exists,
    Entry_Does_Not_Exist,
}