## Item-Descriptor Schema

Items are defined as Json Objects with the following properties:

- **ID** - The ID under which the Item will be registered
- **Name** - The Display Name of the Item
- **Stack-Size** - The Stack Size of the Item (max. Items in a stack)
- **Sprite** - The Sprite of the Item

### Sprites are defined like so:
- **SRC** - The source of the image, can be a:
    - primitive (rectangle or ellipse)
    - loaded image (a texture-id)
    - a subimage (TO BE IMPLENTED) //TODO
- **Origin** - Defines the origin around which the Sprite will be scaled and rotated
- **Scaling** - Defines the Scale of the Sprite
- **Color** - Can be an array of 4 values, **r**, **g**, **b** and **a** <=> **RGBA**