# Copyright 2018 Xored Software, Inc.

import internal/godotinternaltypes, core/godotcoretypes, macros

type
  ColorData* {.byref.} = object
    data: array[16, uint8]

  Vector3Data* {.byref.} = object
    data: array[12, uint8]

  Vector2Data* {.byref.} = object
    data: array[8, uint8]

  PlaneData* {.byref.} = object
    data: array[16, uint8]

  BasisData* {.byref.} = object
    data: array[36, uint8]

  QuatData* {.byref.} = object
    data: array[16, uint8]

  AABBData* {.byref.} = object
    data: array[24, uint8]

  Rect2Data* {.byref.} = object
    data: array[16, uint8]

  Transform2DData* {.byref.} = object
    data: array[24, uint8]

  TransformData* {.byref.} = object
    data: array[48, uint8]

  GDNativeAPIType {.size: sizeof(cuint).} = enum
    GDNativeCore,
    GDNativeExtNativeScript,
    GDNativeExtPluginScript,
    GDNativeExtNativeARVR

  GDNativeAPIHeader = object
    typ: cuint
    version: GDNativeAPIVersion
    next: pointer

  GDNativeNativeScriptAPI1 = object
    typ: cuint
    version: GDNativeAPIVersion
    next: pointer
    nativeScriptRegisterClass: proc (gdnativeHandle: pointer,
                                     name, base: cstring,
                                     createFunc: GodotInstanceCreateFunc,
                                     destroyFunc: GodotInstanceDestroyFunc)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    nativeScriptRegisterToolClass: proc (gdnativeHandle: pointer,
                                         name, base: cstring,
                                         createFunc: GodotInstanceCreateFunc,
                                         destroyFunc: GodotInstanceDestroyFunc)
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    nativeScriptRegisterMethod: proc (gdnativeHandle: pointer,
                                      name, functionName: cstring,
                                      attr: GodotMethodAttributes,
                                      meth: GodotInstanceMethod)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    nativeScriptRegisterProperty: proc (gdnativeHandle: pointer,
                                        name, path: cstring,
                                        attr: ptr GodotPropertyAttributes,
                                        setFunc: GodotPropertySetFunc,
                                        getFunc: GodotPropertyGetFunc)
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    nativeScriptRegisterSignal: proc (gdnativeHandle: pointer, name: cstring,
                                      signal: GodotSignal)
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    nativeScriptGetUserdata: proc (obj: ptr GodotObject): pointer
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

  GDNativeCoreAPI1 = object
    typ: cuint
    version: GDNativeAPIVersion
    next: pointer
    numExtensions: cuint
    extensions: ptr array[100_000, pointer]

    # Color API
    colorNewRGBA: proc (dest: var Color, r, g, b, a: float32)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorNewRGB: proc (dest: var Color, r, g, b: float32)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetR: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetR: proc (self: var Color, r: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetG: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetG: proc (self: var Color, g: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetB: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetB: proc (self: var Color, b: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetA: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetA: proc (self: var Color, a: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetH: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetS: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetV: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorAsString: proc (self: Color): GodotString
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorToRGBA32: proc (self: Color): cint
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorAsARGB32: proc (self: Color): cint
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorGray: proc (self: Color): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    colorInverted: proc (self: Color): ColorData
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorContrasted: proc (self: Color): ColorData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    colorLinearInterpolate: proc (self, other: Color, t: float32): ColorData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    colorBlend: proc (self, other: Color): ColorData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    colorToHtml: proc (self: Color, withAlpha: bool): GodotString
                      {.noconv, raises: [], gcsafe, tags: [], .}
    colorOperatorEqual: proc (self, other: Color): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    colorOperatorLess: proc (self, other: Color): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}

    # Vector2 API
    vector2New: proc (dest: var Vector2, x, y: float32)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    vector2AsString: proc (self: Vector2): GodotString
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Normalized: proc (self: Vector2): Vector2Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Length: proc (self: Vector2): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Angle: proc (self: Vector2): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2LengthSquared: proc (self: Vector2): float32
                                {.noconv, raises: [], gcsafe, tags: [], .}
    vector2IsNormalized: proc (self: Vector2): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2DistanceTo: proc (self, to: Vector2): float32
                            {.noconv, raises: [], gcsafe, tags: [], .}
    vector2DistanceSquaredTo: proc (self, to: Vector2): float32
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    vector2AngleTo: proc (self, to: Vector2): float32
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2AngleToPoint: proc (self, to: Vector2): float32
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2LinearInterpolate: proc (self, b: Vector2, t: float32): Vector2Data
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    vector2CubicInterpolate: proc (self, b, preA, postB: Vector2,
                                    t: float32): Vector2Data
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    vector2Rotated: proc (self: Vector2, phi: float32): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Tangent: proc (self: Vector2): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Floor: proc (self: Vector2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Snapped: proc (self, by: Vector2): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Aspect: proc (self: Vector2): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Dot: proc (self, other: Vector2): float32
                      {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Slide: proc (self, n: Vector2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Bounce: proc (self, n: Vector2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Reflect: proc (self, n: Vector2): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Abs: proc (self: Vector2): Vector2Data
                      {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Clamped: proc (self: Vector2, length: float32): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorAdd: proc (self, other: Vector2): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorSubtract: proc (self, other: Vector2): Vector2Data
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    vector2OperatorMultiplyVector: proc (self, other: Vector2): Vector2Data
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    vector2OperatorMultiplyScalar: proc (self: Vector2, scalar: float32): Vector2Data
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    vector2OperatorDivideVector: proc (self, other: Vector2): Vector2Data
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    vector2OperatorDivideScalar: proc (self: Vector2, scalar: float32): Vector2Data
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    vector2OperatorEqual: proc (self, other: Vector2): bool
                                {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorLess: proc (self, other: Vector2): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorNeg: proc (self: Vector2): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2SetX: pointer
    vector2SetY: pointer
    vector2GetX: pointer
    vector2GetY: pointer

    # Quat API
    quatNew: proc (dest: var Quat, x, y, z, w: float32)
                  {.noconv, raises: [], gcsafe, tags: [], .}
    quatNewWithAxisAngle: proc (dest: Quat, axis: Vector3,
                                angle: float32)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetX: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetX: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetY: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetY: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetZ: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetZ: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetW: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetW: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatAsString: proc (self: Quat): GodotString
                        {.noconv, raises: [], gcsafe, tags: [], .}
    quatLength: proc (self: Quat): float32
                      {.noconv, raises: [], gcsafe, tags: [], .}
    quatLengthSquared: proc (self: Quat): float32
                            {.noconv, raises: [], gcsafe, tags: [], .}
    quatNormalized: proc (self: Quat): QuatData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    quatIsNormalized: proc (self: Quat): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    quatInverse: proc (self: Quat): QuatData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    quatDot: proc (self, other: Quat): float32
                  {.noconv, raises: [], gcsafe, tags: [], .}
    quatXform: proc (self: Quat, v: Vector3): Vector3Data
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSlerp: proc (self, other: Quat, t: float32): QuatData
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSlerpni: proc (self, other: Quat, t: float32): QuatData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    quatCubicSlerp: proc (self, other, preA, postB: Quat, t: float32): QuatData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorMultiply: proc (self: Quat, b: float32): QuatData
                                {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorAdd: proc (self, other: Quat): QuatData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorSubtract: proc (self, other: Quat): QuatData
                                {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorDivide: proc (self: Quat, divider: float32): QuatData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorEqual: proc (self, other: Quat): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorNeg: proc (self: Quat): QuatData
                          {.noconv, raises: [], gcsafe, tags: [], .}

    # Basis API
    basisNewWithRows: pointer
    basisNewWithAxisAndAngle: pointer
    basisNewWithEuler: pointer
    basisAsString: pointer
    basisInverse: pointer
    basisTransposed: pointer
    basisOrthonormalized: pointer
    basisDeterminant: pointer
    basisRotated: pointer
    basisScaled: pointer
    basisGetScale: pointer
    basisGetEuler: pointer
    basisTdotx: pointer
    basisTdoty: pointer
    basisTdotz: pointer
    basisXform: pointer
    basisXformInv: pointer
    basisGetOrthogonalIndex: pointer
    basisNew: pointer
    basisNewWithEulerQuat: pointer
    basisGetElements: pointer
    basisGetAxis: pointer
    basisSetAxis: pointer
    basisGetRow: pointer
    basisSetRow: pointer
    basisOperatorEqual: pointer
    basisOperatorAdd: pointer
    basisOperatorSubstract: pointer
    basisOperatorMultiplyVector: pointer
    basisOperatorMultiplyScalar: pointer

    # Vector3 API
    vector3New: pointer
    vector3AsString: pointer
    vector3MinAxis: pointer
    vector3MaxAxis: pointer
    vector3Length: pointer
    vector3Length_squared: pointer
    vector3IsNormalized: pointer
    vector3Normalized: pointer
    vector3Inverse: pointer
    vector3Snapped: pointer
    vector3Rotated: pointer
    vector3LinearInterpolate: pointer
    vector3CubicInterpolate: pointer
    vector3Dot: pointer
    vector3Cross: pointer
    vector3Outer: pointer
    vector3ToDiagonalMatrix: pointer
    vector3Abs: pointer
    vector3Floor: pointer
    vector3Ceil: pointer
    vector3DistanceTo: pointer
    vector3DistanceSquaredTo: pointer
    vector3AngleTo: pointer
    vector3Slide: pointer
    vector3Bounce: pointer
    vector3Reflect: pointer
    vector3OperatorAdd: pointer
    vector3OperatorSubstract: pointer
    vector3OperatorMultiplyVector: pointer
    vector3OperatorMultiplyScalar: pointer
    vector3OperatorDivideVector: pointer
    vector3OperatorDivideScalar: pointer
    vector3OperatorEqual: pointer
    vector3OperatorLess: pointer
    vector3OperatorNeg: pointer
    vector3SetAxis: pointer
    vector3GetAxis: pointer

    # PoolByteArray API
    poolByteArrayNew: proc (dest: var GodotPoolByteArray)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayNewCopy: proc (dest: var GodotPoolByteArray,
                                src: GodotPoolByteArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayNewWithArray: proc (dest: var GodotPoolByteArray,
                                      src: GodotArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolByteArrayAppend: proc (self: var GodotPoolByteArray,
                                val: byte)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayAppendArray: proc (self: var GodotPoolByteArray,
                                    arr: GodotPoolByteArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolByteArrayInsert: proc (self: var GodotPoolByteArray,
                                idx: cint, val: byte): Error
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayInvert: proc (self: var GodotPoolByteArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayPushBack: proc (self: var GodotPoolByteArray, val: byte)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolByteArrayRemove: proc (self: var GodotPoolByteArray, idx: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayResize: proc (self: var GodotPoolByteArray, size: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayRead: proc (self: GodotPoolByteArray): ptr GodotPoolByteArrayReadAccess
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWrite: proc (self: var GodotPoolByteArray): ptr GodotPoolByteArrayWriteAccess
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArraySet: proc (self: var GodotPoolByteArray, idx: cint, data: byte)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayGet: proc (self: GodotPoolByteArray, idx: cint): byte
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArraySize: proc (self: GodotPoolByteArray): cint
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayDestroy: proc (self: GodotPoolByteArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolIntArray API
    poolIntArrayNew: proc (dest: var GodotPoolIntArray)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayNewCopy: proc (dest: var GodotPoolIntArray,
                                src: GodotPoolIntArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayNewWithArray: proc (dest: var GodotPoolIntArray, src: GodotArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolIntArrayAppend: proc (self: var GodotPoolIntArray, val: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayAppendArray: proc (self: var GodotPoolIntArray,
                                    arr: GodotPoolIntArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolIntArrayInsert: proc (self: var GodotPoolIntArray, idx: cint,
                              val: cint): Error
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayInvert: proc (self: var GodotPoolIntArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayPushBack: proc (self: var GodotPoolIntArray, val: cint)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayRemove: proc (self: var GodotPoolIntArray, idx: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayResize: proc (self: var GodotPoolIntArray, size: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayRead: proc (self: GodotPoolIntArray): ptr GodotPoolIntArrayReadAccess
                           {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWrite: proc (self: var GodotPoolIntArray): ptr GodotPoolIntArrayWriteAccess
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArraySet: proc (self: var GodotPoolIntArray, idx: cint, data: cint)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayGet: proc (self: GodotPoolIntArray, idx: cint): cint
                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArraySize: proc (self: GodotPoolIntArray): cint
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayDestroy: proc (self: GodotPoolIntArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolRealArray API
    poolRealArrayNew: proc (dest: var GodotPoolRealArray)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayNewCopy: proc (dest: var GodotPoolRealArray,
                                src: GodotPoolRealArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayNewWithArray: proc (dest: var GodotPoolRealArray,
                                      src: GodotArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolRealArrayAppend: proc (self: var GodotPoolRealArray, val: float32)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayAppendArray: proc (self: var GodotPoolRealArray,
                                    arr: GodotPoolRealArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolRealArrayInsert: proc (self: var GodotPoolRealArray,
                                idx: cint, val: float32): Error
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayInvert: proc (self: var GodotPoolRealArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayPushBack: proc (self: var GodotPoolRealArray, val: float32)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolRealArrayRemove: proc (self: var GodotPoolRealArray, idx: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayResize: proc (self: var GodotPoolRealArray, size: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayRead: proc (self: GodotPoolRealArray): ptr GodotPoolRealArrayReadAccess
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWrite: proc (self: var GodotPoolRealArray): ptr GodotPoolRealArrayWriteAccess
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArraySet: proc (self: var GodotPoolRealArray, idx: cint,
                            data: float32)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayGet: proc (self: GodotPoolRealArray, idx: cint): float32
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArraySize: proc (self: GodotPoolRealArray): cint
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayDestroy: proc (self: GodotPoolRealArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolStringArray API
    poolStringArrayNew: proc (dest: var GodotPoolStringArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayNewCopy: proc (dest: var GodotPoolStringArray,
                                  src: GodotPoolStringArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolStringArrayNewWithArray: proc (dest: var GodotPoolStringArray,
                                        src: GodotArray)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolStringArrayAppend: proc (self: var GodotPoolStringArray,
                                  val: GodotString)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolStringArrayAppendArray: proc (self: var GodotPoolStringArray,
                                      arr: GodotPoolStringArray)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolStringArrayInsert: proc (self: var GodotPoolStringArray,
                                  idx: cint, val: GodotString): Error
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolStringArrayInvert: proc (self: var GodotPoolStringArray)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolStringArrayPushBack: proc (self: var GodotPoolStringArray,
                                    val: GodotString)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolStringArrayRemove: proc (self: var GodotPoolStringArray, idx: cint)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolStringArrayResize: proc (self: var GodotPoolStringArray, size: cint)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolStringArrayRead: proc (self: GodotPoolStringArray): ptr GodotPoolStringArrayReadAccess
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWrite: proc (self: var GodotPoolStringArray): ptr GodotPoolStringArrayWriteAccess
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArraySet: proc (self: var GodotPoolStringArray, idx: cint,
                              data: GodotString)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayGet: proc (self: GodotPoolStringArray, idx: cint): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArraySize: proc (self: GodotPoolStringArray): cint
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayDestroy: proc (self: GodotPoolStringArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # PoolVector2 API
    poolVector2ArrayNew: proc (dest: var GodotPoolVector2Array)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayNewCopy: proc (dest: var GodotPoolVector2Array,
                                    src: GodotPoolVector2Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayNewWithArray: proc (dest: var GodotPoolVector2Array,
                                        src: GodotArray)
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    poolVector2ArrayAppend: proc (self: var GodotPoolVector2Array, val: Vector2)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayAppendArray: proc (self: var GodotPoolVector2Array,
                                        arr: GodotPoolVector2Array)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolVector2ArrayInsert: proc (self: var GodotPoolVector2Array, idx: cint,
                                  val: Vector2): Error
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayInvert: proc (self: var GodotPoolVector2Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayPushBack: proc (self: var GodotPoolVector2Array,
                                    val: Vector2)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolVector2ArrayRemove: proc (self: var GodotPoolVector2Array, idx: cint)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayResize: proc (self: var GodotPoolVector2Array, size: cint)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayRead: proc (self: GodotPoolVector2Array): ptr GodotPoolVector2ArrayReadAccess
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWrite: proc (self: var GodotPoolVector2Array): ptr GodotPoolVector2ArrayWriteAccess
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArraySet: proc (self: var GodotPoolVector2Array, idx: cint,
                                data: Vector2)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayGet: proc (self: GodotPoolVector2Array, idx: cint): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArraySize: proc (self: GodotPoolVector2Array): cint
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayDestroy: proc (self: GodotPoolVector2Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # PoolVector3 API
    poolVector3ArrayNew: proc (dest: var GodotPoolVector3Array)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayNewCopy: proc (dest: var GodotPoolVector3Array,
                                    src: GodotPoolVector3Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayNewWithArray: proc (dest: var GodotPoolVector3Array,
                                        src: GodotArray)
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    poolVector3ArrayAppend: proc (self: var GodotPoolVector3Array, val: Vector3)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayAppendArray: proc (self: var GodotPoolVector3Array,
                                        arr: GodotPoolVector3Array)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolVector3ArrayInsert: proc (self: var GodotPoolVector3Array, idx: cint,
                                  val: Vector3): Error
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayInvert: proc (self: var GodotPoolVector3Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayPushBack: proc (self: var GodotPoolVector3Array,
                                    val: Vector3) {.noconv, raises: [], gcsafe,
                                                    tags: [], .}
    poolVector3ArrayRemove: proc (self: var GodotPoolVector3Array,
                                  idx: cint) {.noconv, raises: [], gcsafe,
                                                tags: [], .}
    poolVector3ArrayResize: proc (self: var GodotPoolVector3Array,
                                  size: cint) {.noconv, raises: [], gcsafe,
                                                tags: [], .}
    poolVector3ArrayRead: proc (self: GodotPoolVector3Array): ptr GodotPoolVector3ArrayReadAccess
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWrite: proc (self: var GodotPoolVector3Array): ptr GodotPoolVector3ArrayWriteAccess
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArraySet: proc (self: var GodotPoolVector3Array, idx: cint,
                                data: Vector3) {.noconv, raises: [], gcsafe,
                                                tags: [], .}
    poolVector3ArrayGet: proc (self: GodotPoolVector3Array, idx: cint): Vector3Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArraySize: proc (self: GodotPoolVector3Array): cint
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayDestroy: proc (self: GodotPoolVector3Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # PoolColorArray API
    poolColorArrayNew: proc (dest: var GodotPoolColorArray)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayNewCopy: proc (dest: var GodotPoolColorArray,
                                  src: GodotPoolColorArray)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    poolColorArrayNewWithArray: proc (dest: var GodotPoolColorArray,
                                      src: GodotArray)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolColorArrayAppend: proc (self: var GodotPoolColorArray,
                                val: Color)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayAppendArray: proc (self: var GodotPoolColorArray,
                                      arr: GodotPoolColorArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolColorArrayInsert: proc (self: var GodotPoolColorArray,
                                idx: cint, val: Color): Error
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayInvert: proc (self: var GodotPoolColorArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayPushBack: proc (self: var GodotPoolColorArray, val: Color)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolColorArrayRemove: proc (self: var GodotPoolColorArray, idx: cint)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayResize: proc (self: var GodotPoolColorArray, size: cint)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayRead: proc (self: GodotPoolColorArray): ptr GodotPoolColorArrayReadAccess
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWrite: proc (self: var GodotPoolColorArray): ptr GodotPoolColorArrayWriteAccess
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArraySet: proc (self: var GodotPoolColorArray, idx: cint,
                              data: Color)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayGet: proc (self: GodotPoolColorArray, idx: cint): ColorData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArraySize: proc (self: GodotPoolColorArray): cint
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayDestroy: proc (self: GodotPoolColorArray)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}

    # Pool Array Read/Write Access API

    poolByteArrayReadAccessCopy: proc (self: ptr GodotPoolByteArrayReadAccess): ptr GodotPoolByteArrayReadAccess
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayReadAccessPtr: proc (self: ptr GodotPoolByteArrayReadAccess): ptr byte
                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolByteArrayReadAccess)
                                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayReadAccessDestroy: proc (self: ptr GodotPoolByteArrayReadAccess)
                                         {.noconv, raises: [], gcsafe, tags: [], .}

    poolIntArrayReadAccessCopy: proc (self: ptr GodotPoolIntArrayReadAccess): ptr GodotPoolIntArrayReadAccess
                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayReadAccessPtr: proc (self: ptr GodotPoolIntArrayReadAccess): ptr cint
                                    {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolIntArrayReadAccess)
                                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayReadAccessDestroy: proc (self: ptr GodotPoolIntArrayReadAccess)
                                        {.noconv, raises: [], gcsafe, tags: [], .}

    poolRealArrayReadAccessCopy: proc (self: ptr GodotPoolRealArrayReadAccess): ptr GodotPoolRealArrayReadAccess
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayReadAccessPtr: proc (self: ptr GodotPoolRealArrayReadAccess): ptr float32
                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolRealArrayReadAccess)
                                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayReadAccessDestroy: proc (self: ptr GodotPoolRealArrayReadAccess)
                                         {.noconv, raises: [], gcsafe, tags: [], .}

    poolStringArrayReadAccessCopy: proc (self: ptr GodotPoolStringArrayReadAccess): ptr GodotPoolStringArrayReadAccess
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayReadAccessPtr: proc (self: ptr GodotPoolStringArrayReadAccess): ptr GodotString
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolStringArrayReadAccess)
                                                  {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayReadAccessDestroy: proc (self: ptr GodotPoolStringArrayReadAccess)
                                           {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector2ArrayReadAccessCopy: proc (self: ptr GodotPoolVector2ArrayReadAccess): ptr GodotPoolVector2ArrayReadAccess
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayReadAccessPtr: proc (self: ptr GodotPoolVector2ArrayReadAccess): ptr Vector2
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolVector2ArrayReadAccess)
                                                   {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayReadAccessDestroy: proc (self: ptr GodotPoolVector2ArrayReadAccess)
                                            {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector3ArrayReadAccessCopy: proc (self: ptr GodotPoolVector3ArrayReadAccess): ptr GodotPoolVector3ArrayReadAccess
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayReadAccessPtr: proc (self: ptr GodotPoolVector3ArrayReadAccess): ptr Vector3
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolVector3ArrayReadAccess)
                                                   {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayReadAccessDestroy: proc (self: ptr GodotPoolVector3ArrayReadAccess)
                                            {.noconv, raises: [], gcsafe, tags: [], .}

    poolColorArrayReadAccessCopy: proc (self: ptr GodotPoolColorArrayReadAccess): ptr GodotPoolColorArrayReadAccess
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayReadAccessPtr: proc (self: ptr GodotPoolColorArrayReadAccess): ptr Color
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayReadAccessOperatorAssign: proc (self, other: ptr GodotPoolColorArrayReadAccess)
                                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayReadAccessDestroy: proc (self: ptr GodotPoolColorArrayReadAccess)
                                          {.noconv, raises: [], gcsafe, tags: [], .}

    poolByteArrayWriteAccessCopy: proc (self: ptr GodotPoolByteArrayWriteAccess): ptr GodotPoolByteArrayWriteAccess
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWriteAccessPtr: proc (self: ptr GodotPoolByteArrayWriteAccess): ptr byte
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolByteArrayWriteAccess)
                                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWriteAccessDestroy: proc (self: ptr GodotPoolByteArrayWriteAccess)
                                          {.noconv, raises: [], gcsafe, tags: [], .}

    poolIntArrayWriteAccessCopy: proc (self: ptr GodotPoolIntArrayWriteAccess): ptr GodotPoolIntArrayWriteAccess
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWriteAccessPtr: proc (self: ptr GodotPoolIntArrayWriteAccess): ptr cint
                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolIntArrayWriteAccess)
                                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWriteAccessDestroy: proc (self: ptr GodotPoolIntArrayWriteAccess)
                                         {.noconv, raises: [], gcsafe, tags: [], .}

    poolRealArrayWriteAccessCopy: proc (self: ptr GodotPoolRealArrayWriteAccess): ptr GodotPoolRealArrayWriteAccess
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWriteAccessPtr: proc (self: ptr GodotPoolRealArrayWriteAccess): ptr float32
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolRealArrayWriteAccess)
                                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWriteAccessDestroy: proc (self: ptr GodotPoolRealArrayWriteAccess)
                                          {.noconv, raises: [], gcsafe, tags: [], .}

    poolStringArrayWriteAccessCopy: proc (self: ptr GodotPoolStringArrayWriteAccess): ptr GodotPoolStringArrayWriteAccess
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWriteAccessPtr: proc (self: ptr GodotPoolStringArrayWriteAccess): ptr GodotString
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolStringArrayWriteAccess)
                                                   {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWriteAccessDestroy: proc (self: ptr GodotPoolStringArrayWriteAccess)
                                            {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector2ArrayWriteAccessCopy: proc (self: ptr GodotPoolVector2ArrayWriteAccess): ptr GodotPoolVector2ArrayWriteAccess
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWriteAccessPtr: proc (self: ptr GodotPoolVector2ArrayWriteAccess): ptr Vector2
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolVector2ArrayWriteAccess)
                                                    {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWriteAccessDestroy: proc (self: ptr GodotPoolVector2ArrayWriteAccess)
                                             {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector3ArrayWriteAccessCopy: proc (self: ptr GodotPoolVector3ArrayWriteAccess): ptr GodotPoolVector3ArrayWriteAccess
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWriteAccessPtr: proc (self: ptr GodotPoolVector3ArrayWriteAccess): ptr Vector3
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolVector3ArrayWriteAccess)
                                                    {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWriteAccessDestroy: proc (self: ptr GodotPoolVector3ArrayWriteAccess)
                                             {.noconv, raises: [], gcsafe, tags: [], .}

    poolColorArrayWriteAccessCopy: proc (self: ptr GodotPoolColorArrayWriteAccess): ptr GodotPoolColorArrayWriteAccess
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWriteAccessPtr: proc (self: ptr GodotPoolColorArrayWriteAccess): ptr Color
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWriteAccessOperatorAssign: proc (self, other: ptr GodotPoolColorArrayWriteAccess)
                                                  {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWriteAccessDestroy: proc (self: ptr GodotPoolColorArrayWriteAccess)
                                           {.noconv, raises: [], gcsafe, tags: [], .}

    # Array API
    arrayNew: proc (dest: var GodotArray)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayNewCopy: proc (dest: var GodotArray, src: GodotArray)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayNewPoolColorArray: proc (dest: var GodotArray, src: GodotPoolColorArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    arrayNewPoolVector3Array: proc (dest: var GodotArray,
                                    src: GodotPoolVector3Array)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    arrayNewPoolVector2Array: proc (dest: var GodotArray,
                                    src: GodotPoolVector2Array)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    arrayNewPoolStringArray: proc (dest: var GodotArray,
                                    src: GodotPoolStringArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    arrayNewPoolRealArray: proc (dest: var GodotArray, src: GodotPoolRealArray)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    arrayNewPoolIntArray: proc (dest: var GodotArray, src: GodotPoolIntArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    arrayNewPoolByteArray: proc (dest: var GodotArray, src: GodotPoolByteArray)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    arraySet: proc (self: var GodotArray, idx: cint, val: GodotVariant)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayGet: proc (self: GodotArray, idx: cint): GodotVariant
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayOperatorIndex: proc (self: var GodotArray, idx: cint): ptr GodotVariant
                              {.noconv, raises: [], gcsafe, tags: [], .}
    arrayOperatorIndexConst: pointer
    arrayAppend: proc (self: var GodotArray, val: GodotVariant)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayClear: proc (self: var GodotArray)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayCount: proc (self: GodotArray, val: GodotVariant): cint
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayEmpty: proc (self: GodotArray): bool
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayErase: proc (self: var GodotArray, val: GodotVariant)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayFront: proc (self: GodotArray): GodotVariant
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayBack: proc (self: GodotArray): GodotVariant
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayFind: proc (self: GodotArray, what: GodotVariant, fromIdx: cint): cint
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayFindLast: proc (self: GodotArray, what: GodotVariant): cint
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayHas: proc (self: GodotArray, val: GodotVariant): bool
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayHash: proc (self: GodotArray): cint
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayInsert: proc (self: var GodotArray, pos: cint, val: GodotVariant): Error
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayInvert: proc (self: var GodotArray)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPopBack: proc (self: GodotArray): GodotVariant
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPopFront: proc (self: GodotArray): GodotVariant
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPushBack: proc (self: var GodotArray, val: GodotVariant)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPushFront: proc (self: var GodotArray, val: GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    arrayRemove: proc (self: var GodotArray, idx: cint)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayResize: proc (self: var GodotArray, size: cint)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayRFind: proc (self: GodotArray, what: GodotVariant, fromIdx: cint): cint
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arraySize: proc (self: GodotArray): cint
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arraySort: proc (self: var GodotArray)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arraySortCustom: proc (self: var GodotArray, obj: ptr GodotObject,
                            f: GodotString)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    arrayBSearch: proc (self: var GodotArray, val: ptr GodotVariant,
                        before: bool)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayBSearchCustom: proc (self: var GodotArray, val: ptr GodotVariant,
                              obj: ptr GodotObject, f: GodotString,
                              before: bool)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    arrayDestroy: proc (self: var GodotArray)
                        {.noconv, raises: [], gcsafe, tags: [], .}

    # Dictionary API
    dictionaryNew: proc (dest: var GodotDictionary)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryNewCopy: proc (dest: var GodotDictionary, src: GodotDictionary)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryDestroy: proc (self: var GodotDictionary)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    dictionarySize: proc (self: GodotDictionary): cint
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryEmpty: proc (self: GodotDictionary): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryClear: proc (self: var GodotDictionary)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryHas: proc (self: GodotDictionary, key: GodotVariant): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryHasAll: proc (self: GodotDictionary, keys: GodotArray): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryErase: proc (self: var GodotDictionary, key: GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryHash: proc (self: GodotDictionary): cint
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryKeys: proc (self: GodotDictionary): GodotArray
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryValues: proc (self: GodotDictionary): GodotArray
                            {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryGet: proc (self: GodotDictionary, key: GodotVariant): GodotVariant
                        {.noconv, raises: [], gcsafe, tags: [], .}
    dictionarySet: proc (self: var GodotDictionary, key, value: GodotVariant)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryOperatorIndex: proc (self: var GodotDictionary,
                                   key: GodotVariant): ptr GodotVariant
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    dictionaryOperatorIndexConst: pointer
    dictionaryNext: proc (self: GodotDictionary,
                          key: GodotVariant): ptr GodotVariant
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryOperatorEqual: proc (self, other: GodotDictionary): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    dictionaryToJson: proc (self: GodotDictionary): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}

    # NodePath API
    nodePathNew: proc (dest: var GodotNodePath, src: GodotString)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathNewCopy: proc (dest: var GodotNodePath, src: GodotNodePath)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathDestroy: proc (self: var GodotNodePath)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathAsString: proc (self: GodotNodePath): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathIsAbsolute: proc (self: GodotNodePath): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetNameCount: proc (self: GodotNodePath): cint
                                {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetName: proc (self: GodotNodePath, idx: cint): GodotString
                          {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetSubnameCount: proc (self: GodotNodePath): cint
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    nodePathGetSubname: proc (self: GodotNodePath, idx: cint): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetConcatenatedSubnames: proc (self: GodotNodePath): GodotString
                                          {.noconv, raises: [], gcsafe,
                                            tags: [], .}
    nodePathIsEmpty: proc (self: GodotNodePath): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathOperatorEqual: proc (self, other: GodotNodePath): bool
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}

    # Plane API
    planeNewWithReals: proc (dest: var Plane, a, b, c, d: float32)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeNewWithVectors: proc (dest: var Plane, v1, v2, v3: Vector3)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeNewWithNormal: proc (dest: var Plane, normal: Vector3, d: float32)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeAsString: proc (self: Plane): GodotString
                        {.noconv, raises: [], gcsafe, tags: [], .}
    planeNormalized: proc (self: Plane): PlaneData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeCenter: proc (self: Plane): Vector3Data
                      {.noconv, raises: [], gcsafe, tags: [], .}
    planeGetAnyPoint: proc (self: Plane): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeIsPointOver: proc (self: Plane, point: Vector3): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeDistanceTo: proc (self: Plane, point: Vector3): float32
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeHasPoint: proc (self: Plane, point: Vector3, epsilon: float32): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    planeProject: proc (self: Plane, point: Vector3): Vector3Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    planeIntersect3: proc (self: Plane, dest: var Vector3, b, c: Plane): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeIntersectsRay: proc (self: Plane, dest: var Vector3,
                              point, dir: Vector3): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeIntersectsSegment: proc (self: Plane, dest: var Vector3,
                                  segmentBegin, segmentEnd: Vector3): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    planeOperatorNeg: proc (self: Plane): PlaneData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeOperatorEqual: proc (self, other: Plane): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeSetNormal: proc (self: var Plane, normal: Vector3)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeGetNormal: proc (self: Plane): Vector3Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeGetD: proc (self: Plane): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    planeSetD: proc (self: var Plane, d: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}

    # Rect2 API
    rect2NewWithPositionAndSize: proc (dest: var Rect2, pos, size: Vector2)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    rect2New: proc (dest: var Rect2, x, y, width, height: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    rect2AsString: proc (self: Rect2): GodotString
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2GetArea: proc (self: Rect2): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Intersects: proc (self, other: Rect2): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Encloses: proc (self, other: Rect2): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2HasNoArea: proc (self: Rect2): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Clip: proc (self, other: Rect2): Rect2Data
                    {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Merge: proc (self, other: Rect2): Rect2Data
                      {.noconv, raises: [], gcsafe, tags: [], .}
    rect2HasPoint: proc (self: Rect2, point: Vector2): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Grow: proc (self: Rect2, by: float32): Rect2Data
                    {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Expand: proc (self: Rect2, to: Vector2): Rect2Data
                      {.noconv, raises: [], gcsafe, tags: [], .}
    rect2OperatorEqual: proc (self, other: Rect2): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    rect2GetPosition: proc (self: Rect2): Vector2Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    rect2GetSize: proc (self: Rect2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2SetPosition: proc (self: var Rect2, pos: Vector2)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    rect2SetSize: proc (self: var Rect2, size: Vector2)
                        {.noconv, raises: [], gcsafe, tags: [], .}

    # AABB API
    aabbNew: proc (dest: var AABB, pos, size: Vector3)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetPosition: proc (self: AABB): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbSetPosition: proc (self: var AABB, pos: Vector3)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetSize: proc (self: AABB): Vector3Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbSetSize: proc (self: var AABB, pos: Vector3)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbAsString: proc (self: AABB): GodotString
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetArea: proc (self: AABB): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbHasNoArea: proc (self: AABB): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    aabbHasNoSurface: proc (self: AABB): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersects: proc (self, other: AABB): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    aabbEncloses: proc (self, other: AABB): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbMerge: proc (self, other: AABB): AABBData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersection: proc (self, other: AABB): AABBData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersectsPlane: proc (self: AABB, plane: Plane): bool
                                {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersectsSegment: proc (self: AABB, vFrom, vTo: Vector3): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    aabbHasPoint: proc (self: AABB, point: Vector3): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetSupport: proc (self: AABB, dir: Vector3): Vector3Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetLongestAxis: proc (self: AABB): Vector3Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetLongestAxisIndex: proc (self: AABB): cint
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    aabbGetLongestAxisSize: proc (self: AABB): float32
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    aabbGetShortestAxis: proc (self: AABB): Vector3Data
                                {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetShortestAxisIndex: proc (self: AABB): cint
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    aabbGetShortestAxisSize: proc (self: AABB): float32
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    aabbExpand: proc (self: AABB, toPoint: Vector3): AABBData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGrow: proc (self: AABB, by: float32): AABBData
                    {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetEndpoint: proc (self: AABB, idx: cint): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbOperatorEqual: proc (self, other: AABB): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}

    # RID API
    ridNew: proc (dest: var RID)
                  {.noconv, raises: [], gcsafe, tags: [], .}
    ridGetID: proc (self: RID): cint
                    {.noconv, raises: [], gcsafe, tags: [], .}
    ridNewWithResource: proc (dest: var RID, obj: ptr GodotObject)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    ridOperatorEqual: proc (self, other: RID): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    ridOperatorLess: proc (self, other: RID): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}

    # Transform API
    transformNewWithAxisOrigin: proc (dest: var Transform,
                                      xAxis, yAxis, zAxis, origin: Vector3)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transformNew: proc (dest: var Transform, basis: Basis, origin: Vector3)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    transformGetBasis: proc (self: Transform): BasisData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformSetBasis: proc (self: var Transform, basis: Basis)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformGetOrigin: proc (self: Transform): Vector3Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformSetOrigin: proc (self: var Transform, v: Vector3)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformAsString: proc (self: Transform): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformInverse: proc (self: Transform): TransformData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformAffineInverse: proc (self: Transform): TransformData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transformOrthonormalized: proc (self: Transform): TransformData
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transformRotated: proc (self: Transform, axis: Vector3,
                            phi: float32): TransformData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformScaled: proc (self: Transform, scale: Vector3): TransformData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    transformTranslated: proc (self: Transform, offset: Vector3): TransformData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformLookingAt: proc (self: Transform, target, up: Vector3): TransformData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformXformPlane: proc (self: Transform, plane: Plane): PlaneData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformXformInvPlane: proc (self: Transform, plane: Plane): PlaneData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transformNewIdentity: proc (dest: var Transform)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    transformOperatorEqual: proc (self, other: Transform): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transformOperatorMultiply: proc (self, other: Transform): TransformData
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transformXformVector3: proc (self: Transform, v: Vector3): Vector3Data
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    transformXformInvVector3: proc (self: Transform, v: Vector3): Vector3Data
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transformXformAABB: proc (self: Transform, v: AABB): AABBData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformXformInvAABB: proc (self: Transform, v: AABB): AABBData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # Transform2D API
    transform2DNew: proc (dest: var Transform2D, rot: float32, pos: Vector2)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DNewAxisOrigin: proc (dest: var Transform2D,
                                    xAxis, yAxis, origin: Vector2)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transform2DAsString: proc (self: Transform2D): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DInverse: proc (self: Transform2D): Transform2DData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DAffineInverse: proc (self: Transform2D): Transform2DData
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transform2DGetRotation: proc (self: Transform2D): float32
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transform2DGetOrigin: proc (self: Transform2D): Vector2Data
                                {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DGetScale: proc (self: Transform2D): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DOrthonormalized: proc (self: Transform2D): Transform2DData
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DRotated: proc (self: Transform2D, phi: float32): Transform2DData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DScaled: proc (self: Transform2D, scale: Vector2): Transform2DData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DTranslated: proc (self: Transform2D, offset: Vector2): Transform2DData
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    transform2DXformVector2: proc (self: Transform2D, v: Vector2): Vector2Data
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transform2DXformInvVector2: proc (self: Transform2D, v: Vector2): Vector2Data
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DBasisXformVector2: proc (self: Transform2D, v: Vector2): Vector2Data
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    transform2DBasisXformInvVector2: proc (self: Transform2D,
                                            v: Vector2): Vector2Data
                                          {.noconv, raises: [], gcsafe, tags: [],
                                            .}
    transform2DInterpolateWith: proc (self, other: Transform2D,
                                      t: float32): Transform2DData
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DOperatorEqual: proc (self, other: Transform2D): bool
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transform2DOperatorMultiply: proc (self, other: Transform2D): Transform2DData
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DNewIdentity: proc (dest: var Transform2D)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transform2DXformRect2: proc (self: Transform2D, v: Rect2): Rect2Data
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    transform2DXformInvRect2: proc (self: Transform2D, v: Rect2): Rect2Data
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}

    # Variant API
    variantGetType: proc (v: GodotVariant): VariantType
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewCopy: proc (dest: var GodotVariant, src: GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewNil: proc (dest: var GodotVariant)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewBool: proc (dest: var GodotVariant, val: bool)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewUInt: proc (dest: var GodotVariant, val: uint64)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewInt: proc (dest: var GodotVariant, val: int64)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewReal: proc (dest: var GodotVariant, val: float64)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewString: proc (dest: var GodotVariant, val: GodotString)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewVector2: proc (dest: var GodotVariant, val: Vector2)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewRect2: proc (dest: var GodotVariant, val: Rect2)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewVector3: proc (dest: var GodotVariant, val: Vector3)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewTransform2D: proc (dest: var GodotVariant, val: Transform2D)
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    variantNewPlane: proc (dest: var GodotVariant, val: Plane)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewQuat: proc (dest: var GodotVariant, val: Quat)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewAABB: proc (dest: var GodotVariant, val: AABB)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewBasis: proc (dest: var GodotVariant, val: Basis)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewTransform: proc (dest: var GodotVariant, val: Transform)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewColor: proc (dest: var GodotVariant, val: Color)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewNodePath: proc (dest: var GodotVariant, val: GodotNodePath)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewRID: proc (dest: var GodotVariant, val: RID)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewObject: proc (dest: var GodotVariant, val: ptr GodotObject)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewDictionary: proc (dest: var GodotVariant, val: GodotDictionary)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewArray: proc (dest: var GodotVariant, val: GodotArray)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewPoolByteArray: proc (dest: var GodotVariant,
                                    val: GodotPoolByteArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantNewPoolIntArray: proc (dest: var GodotVariant, val: GodotPoolIntArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantNewPoolRealArray: proc (dest: var GodotVariant,
                                    val: GodotPoolRealArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantNewPoolStringArray: proc (dest: var GodotVariant,
                                      val: GodotPoolStringArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantNewPoolVector2Array: proc (dest: var GodotVariant,
                                      val: GodotPoolVector2Array)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    variantNewPoolVector3Array: proc (dest: var GodotVariant,
                                      val: GodotPoolVector3Array)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    variantNewPoolColorArray: proc (dest: var GodotVariant,
                                    val: GodotPoolColorArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantAsBool: proc (self: GodotVariant): bool
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsUInt: proc (self: GodotVariant): uint64
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsInt: proc (self: GodotVariant): int64
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsReal: proc (self: GodotVariant): float64
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsString: proc (self: GodotVariant): GodotString
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsVector2: proc (self: GodotVariant): Vector2Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsRect2: proc (self: GodotVariant): Rect2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsVector3: proc (self: GodotVariant): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsTransform2D: proc (self: GodotVariant): Transform2DData
                                {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsPlane: proc (self: GodotVariant): PlaneData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsQuat: proc (self: GodotVariant): QuatData
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsAABB: proc (self: GodotVariant): AABBData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsBasis: proc (self: GodotVariant): BasisData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsTransform: proc (self: GodotVariant): TransformData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsColor: proc (self: GodotVariant): ColorData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsNodePath: proc (self: GodotVariant): GodotNodePath
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsRID: proc (self: GodotVariant): RID
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsObject: proc (self: GodotVariant): ptr GodotObject
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsDictionary: proc (self: GodotVariant): GodotDictionary
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsArray: proc (self: GodotVariant): GodotArray
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsPoolByteArray: proc (self: GodotVariant): GodotPoolByteArray
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantAsPoolIntArray: proc (self: GodotVariant): GodotPoolIntArray
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    variantAsPoolRealArray: proc (self: GodotVariant): GodotPoolRealArray
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantAsPoolStringArray: proc (self: GodotVariant): GodotPoolStringArray
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantAsPoolVector2Array: proc (self: GodotVariant): GodotPoolVector2Array
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantAsPoolVector3Array: proc (self: GodotVariant): GodotPoolVector3Array
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantAsPoolColorArray: proc (self: GodotVariant): GodotPoolColorArray
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantCall: proc (self: var GodotVariant, meth: GodotString,
                        args: ptr array[MAX_ARG_COUNT, ptr GodotVariant],
                        argcount: cint,
                        callError: var VariantCallError): GodotVariant
                      {.noconv, raises: [], gcsafe, tags: [], .}
    variantHasMethod: proc (self: GodotVariant, meth: GodotString): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantOperatorEqual: proc (self, other: GodotVariant): bool
                                {.noconv, raises: [], gcsafe, tags: [], .}
    variantOperatorLess: proc (self, other: GodotVariant): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantHashCompare: proc (self, other: GodotVariant): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantBooleanize: proc (self: GodotVariant): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantDestroy: proc (self: var GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}

    # String API
    charStringLength: proc (self: GodotCharString): cint
                           {.noconv, raises: [], gcsafe, tags: [], .}
    charStringGetData: proc (self: GodotCharString): cstring
                            {.noconv, raises: [], gcsafe, tags: [], .}
    charStringDestroy: proc (self: var GodotCharString)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    stringNew: proc (dest: var GodotString)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    stringNewCopy: proc (dest: var GodotString, src: GodotString)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    stringNewWithWideString: pointer
    stringOperatorIndex: pointer
    stringOperatorIndexConst: pointer
    stringWideStr: proc (self: GodotString): ptr cwchar_t
                        {.noconv, raises: [], gcsafe, tags: [], .}
    stringOperatorEqual: proc (self, other: GodotString): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    stringOperatorLess: proc (self, other: GodotString): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    stringOperatorPlus: proc (self, other: GodotString): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    stringLength: proc (self: GodotString): cint
                        {.noconv, raises: [], gcsafe, tags: [], .}
    stringCasecmpTo: pointer
    stringNocasecmpTo: pointer
    stringNaturalnocasecmpTo: pointer
    stringBeginsWith: pointer
    stringBeginsWithCharArray: pointer
    stringBigrams: pointer
    stringChr: pointer
    stringEndsWith: pointer
    stringFind: pointer
    stringFindFrom: pointer
    stringFindmk: pointer
    stringFindmkFrom: pointer
    stringFindmkFromInPlace: pointer
    stringFindn: pointer
    stringFindnFrom: pointer
    stringFindLast: pointer
    stringFormat: pointer
    stringFormatWithCustomPlaceholder: pointer
    stringHexEncodeBuffer: pointer
    stringHexToInt: pointer
    stringHexToIntWithoutPrefix: pointer
    stringInsert: pointer
    stringIsNumeric: pointer
    stringIsSubsequenceOf: pointer
    stringIsSubsequenceOfi: pointer
    stringLpad: pointer
    stringLpadWithCustomCharacter: pointer
    stringMatch: pointer
    stringMatchn: pointer
    stringMd5: pointer
    stringNum: pointer
    stringNumInt64: pointer
    stringNumInt64Capitalized: pointer
    stringNumReal: pointer
    stringNumScientific: pointer
    stringNumWithDecimals: pointer
    stringPadDecimals: pointer
    stringPadZeros: pointer
    stringReplaceFirst: pointer
    stringReplace: pointer
    stringReplacen: pointer
    stringRfind: pointer
    stringRfindn: pointer
    stringRfindFrom: pointer
    stringRfindnFrom: pointer
    stringRpad: pointer
    stringRpadWithCustomCharacter: pointer
    stringSimilarity: pointer
    stringSprintf: pointer
    stringSubstr: pointer
    stringToDouble: pointer
    stringToFloat: pointer
    stringToInt: pointer
    stringCamelcaseToUnderscore: pointer
    stringCamelcaseToUnderscoreLowercased: pointer
    stringCapitalize: pointer
    stringCharToDouble: pointer
    stringCharToInt: pointer
    stringWcharToInt: pointer
    stringCharToIntWithLen: pointer
    stringCharToInt64WithLen: pointer
    stringHexToInt64: pointer
    stringHexToInt64WithPrefix: pointer
    stringToInt64: pointer
    stringUnicodeCharToDouble: pointer
    stringGetSliceCount: pointer
    stringGetSlice: pointer
    stringGetSlicec: pointer
    stringSplit: pointer
    stringSplitAllowEmpty: pointer
    stringSplitFloats: pointer
    stringSplitFloatsAllowsEmpty: pointer
    stringSplitFloatsMk: pointer
    stringSplitFloatsMkAllowsEmpty: pointer
    stringSplitInts: pointer
    stringSplitIntsAllowsEmpty: pointer
    stringSplitIntsMk: pointer
    stringSplitIntsMkAllowsEmpty: pointer
    stringSplitSpaces: pointer
    stringCharLowercase: pointer
    stringCharUppercase: pointer
    stringToLower: pointer
    stringToUpper: pointer
    stringGetBasename: pointer
    stringGetExtension: pointer
    stringLeft: pointer
    stringOrdAt: pointer
    stringPlusFile: pointer
    stringRight: pointer
    stringStripEdges: pointer
    stringStripEscapes: pointer
    stringErase: pointer
    stringAscii: pointer
    stringAsciiExtended: pointer
    stringUtf8: proc (self: GodotString): GodotCharString
                     {.noconv, raises: [], gcsafe, tags: [], .}
    stringParseUtf8: pointer
    stringParseUtf8WithLen: pointer
    stringCharsToUtf8: proc (str: cstring): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}
    stringCharsToUtf8WithLen: proc (str: cstring, len: cint): GodotString
                                   {.noconv, raises: [], gcsafe, tags: [], .}
    stringHash: pointer
    stringHash64: pointer
    stringHashChars: pointer
    stringHashCharsWithLen: pointer
    stringHashUtf8Chars: pointer
    stringHashUtf8CharsWithLen: pointer
    stringMd5Buffer: pointer
    stringMd5Text: pointer
    stringSha256Buffer: pointer
    stringSha256Text: pointer
    stringEmpty: pointer
    stringGetBaseDir: pointer
    stringGetFile: pointer
    stringHumanizeSize: pointer
    stringIsAbsPath: pointer
    stringIsRelPath: pointer
    stringIsResourceFile: pointer
    stringPathTo: pointer
    stringPathToFile: pointer
    stringSimplifyPath: pointer
    stringCEscape: pointer
    stringCEscapeMultiline: pointer
    stringCUnescape: pointer
    stringHttpEscape: pointer
    stringHttpUnescape: pointer
    stringJsonEscape: pointer
    stringWordWrap: pointer
    stringXmlEscape: pointer
    stringXmlEscapeWithQuotes: pointer
    stringXmlUnescape: pointer
    stringPercentDecode: pointer
    stringPercentEncode: pointer
    stringIsValidFloat: pointer
    stringIsValidHexNumber: pointer
    stringIsValidHtmlColor: pointer
    stringIsValidIdentifier: pointer
    stringIsValidInteger: pointer
    stringIsValidIpAddress: pointer
    stringDestroy: proc (self: var GodotString)
                        {.noconv, raises: [], gcsafe, tags: [], .}

    # StringName API
    stringNameNew: pointer
    stringNameNewData: pointer
    stringNameGetName: pointer
    stringNameGetHash: pointer
    stringNameGetDataUniquePointer: pointer
    stringNameOperatorEqual: pointer
    stringNameOperatorLess: pointer
    stringNameDestroy: pointer

    # Misc API
    objectDestroy: proc (self: ptr GodotObject)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    globalGetSingleton: proc (name: cstring): ptr GodotObject
                              {.noconv, raises: [], gcsafe, tags: [], .}
    methodBindGetMethod: proc (className,
                                methodName: cstring): ptr GodotMethodBind
                              {.noconv, raises: [], gcsafe, tags: [], .}
    methodBindPtrCall: proc (methodBind: ptr GodotMethodBind,
                              obj: ptr GodotObject,
                              args: ptr array[MAX_ARG_COUNT, pointer],
                              ret: pointer)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    methodBindCall: proc (methodBind: ptr GodotMethodBind, obj: ptr GodotObject,
                          args: ptr array[MAX_ARG_COUNT, ptr GodotVariant],
                          argCount: cint,
                          callError: var VariantCallError): GodotVariant
                          {.noconv, raises: [], gcsafe, tags: [], .}
    getClassConstructor: proc (className: cstring): GodotClassConstructor
                              {.noconv, raises: [], gcsafe, tags: [], .}
    getGlobalConstants: pointer
    registerNativeCallType: proc (callType: cstring,
                                  cb: proc (procHandle: pointer,
                                            args: ptr GodotArray): GodotVariant
                                           {.noconv.}) {.noconv.}
    alloc: proc (bytes: cint): pointer
                {.noconv, raises: [], gcsafe, tags: [], .}
    realloc: proc (p: pointer, bytes: cint): pointer
                  {.noconv, raises: [], gcsafe, tags: [], .}
    free: proc (p: pointer) {.noconv, raises: [], gcsafe, tags: [], .}

    printError: proc (description, function, file: cstring, line: cint)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    printWarning: proc (description, function, file: cstring, line: cint)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    print: proc (message: GodotString)
                {.noconv, raises: [], gcsafe, tags: [], .}

  GDNativeAPI* = object
    # Color API
    colorNewRGBA*: proc (dest: var Color, r, g, b, a: float32)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorNewRGB*: proc (dest: var Color, r, g, b: float32)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetR*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetR*: proc (self: var Color, r: float32)
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetG*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetG*: proc (self: var Color, g: float32)
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetB*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetB*: proc (self: var Color, b: float32)
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetA*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorSetA*: proc (self: var Color, a: float32)
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetH*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetS*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorGetV*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorAsString*: proc (self: Color): GodotString
                         {.noconv, raises: [], gcsafe, tags: [], .}
    colorToRGBA32*: proc (self: Color): cint
                         {.noconv, raises: [], gcsafe, tags: [], .}
    colorAsARGB32*: proc (self: Color): cint
                         {.noconv, raises: [], gcsafe, tags: [], .}
    colorGray*: proc (self: Color): float32
                     {.noconv, raises: [], gcsafe, tags: [], .}
    colorInverted*: proc (self: Color): ColorData
                        {.noconv, raises: [], gcsafe, tags: [], .}
    colorContrasted*: proc (self: Color): ColorData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    colorLinearInterpolate*: proc (self, other: Color, t: float32): ColorData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    colorBlend*: proc (self, other: Color): ColorData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    colorToHtml*: proc (self: Color, withAlpha: bool): GodotString
                       {.noconv, raises: [], gcsafe, tags: [], .}
    colorOperatorEqual*: proc (self, other: Color): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    colorOperatorLess*: proc (self, other: Color): bool
                             {.noconv, raises: [], gcsafe, tags: [], .}

    # Vector2 API
    vector2New*: proc (dest: var Vector2, x, y: float32)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    vector2AsString*: proc (self: Vector2): GodotString
                           {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Normalized*: proc (self: Vector2): Vector2Data
                             {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Length*: proc (self: Vector2): float32
                         {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Angle*: proc (self: Vector2): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2LengthSquared*: proc (self: Vector2): float32
                                {.noconv, raises: [], gcsafe, tags: [], .}
    vector2IsNormalized*: proc (self: Vector2): bool
                               {.noconv, raises: [], gcsafe, tags: [], .}
    vector2DistanceTo*: proc (self, to: Vector2): float32
                             {.noconv, raises: [], gcsafe, tags: [], .}
    vector2DistanceSquaredTo*: proc (self, to: Vector2): float32
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    vector2AngleTo*: proc (self, to: Vector2): float32
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2AngleToPoint*: proc (self, to: Vector2): float32
                               {.noconv, raises: [], gcsafe, tags: [], .}
    vector2LinearInterpolate*: proc (self, b: Vector2, t: float32): Vector2Data
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    vector2CubicInterpolate*: proc (self, b, preA, postB: Vector2,
                                    t: float32): Vector2Data
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    vector2Rotated*: proc (self: Vector2, phi: float32): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Tangent*: proc (self: Vector2): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Floor*: proc (self: Vector2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Snapped*: proc (self, by: Vector2): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Aspect*: proc (self: Vector2): float32
                         {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Dot*: proc (self, other: Vector2): float32
                      {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Slide*: proc (self, n: Vector2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Bounce*: proc (self, n: Vector2): Vector2Data
                         {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Reflect*: proc (self, n: Vector2): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Abs*: proc (self: Vector2): Vector2Data
                      {.noconv, raises: [], gcsafe, tags: [], .}
    vector2Clamped*: proc (self: Vector2, length: float32): Vector2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorAdd*: proc (self, other: Vector2): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorSubtract*: proc (self, other: Vector2): Vector2Data
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    vector2OperatorMultiplyVector*: proc (self, other: Vector2): Vector2Data
                                         {.noconv, raises: [], gcsafe, tags: [],
                                           .}
    vector2OperatorMultiplyScalar*: proc (self: Vector2, scalar: float32): Vector2Data
                                         {.noconv, raises: [], gcsafe, tags: [],
                                           .}
    vector2OperatorDivideVector*: proc (self, other: Vector2): Vector2Data
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    vector2OperatorDivideScalar*: proc (self: Vector2, scalar: float32): Vector2Data
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    vector2OperatorEqual*: proc (self, other: Vector2): bool
                                {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorLess*: proc (self, other: Vector2): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    vector2OperatorNeg*: proc (self: Vector2): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}

    # Quat API
    quatNew*: proc (dest: var Quat, x, y, z, w: float32)
                   {.noconv, raises: [], gcsafe, tags: [], .}
    quatNewWithAxisAngle*: proc (dest: Quat, axis: Vector3,
                                 angle: float32)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetX*: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetX*: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetY*: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetY*: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetZ*: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetZ*: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatGetW*: proc (self: Quat): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatSetW*: proc (self: var Quat, val: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    quatAsString*: proc (self: Quat): GodotString
                        {.noconv, raises: [], gcsafe, tags: [], .}
    quatLength*: proc (self: Quat): float32
                      {.noconv, raises: [], gcsafe, tags: [], .}
    quatLengthSquared*: proc (self: Quat): float32
                             {.noconv, raises: [], gcsafe, tags: [], .}
    quatNormalized*: proc (self: Quat): QuatData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    quatIsNormalized*: proc (self: Quat): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    quatInverse*: proc (self: Quat): QuatData
                       {.noconv, raises: [], gcsafe, tags: [], .}
    quatDot*: proc (self, other: Quat): float32
                   {.noconv, raises: [], gcsafe, tags: [], .}
    quatXform*: proc (self: Quat, v: Vector3): Vector3Data
                     {.noconv, raises: [], gcsafe, tags: [], .}
    quatSlerp*: proc (self, other: Quat, t: float32): QuatData
                     {.noconv, raises: [], gcsafe, tags: [], .}
    quatSlerpni*: proc (self, other: Quat, t: float32): QuatData
                       {.noconv, raises: [], gcsafe, tags: [], .}
    quatCubicSlerp*: proc (self, other, preA, postB: Quat, t: float32): QuatData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorMultiply*: proc (self: Quat, b: float32): QuatData
                                {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorAdd*: proc (self, other: Quat): QuatData
                           {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorSubtract*: proc (self, other: Quat): QuatData
                                {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorDivide*: proc (self: Quat, divider: float32): QuatData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorEqual*: proc (self, other: Quat): bool
                             {.noconv, raises: [], gcsafe, tags: [], .}
    quatOperatorNeg*: proc (self: Quat): QuatData
                           {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolByteArray API
    poolByteArrayNew*: proc (dest: var GodotPoolByteArray)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayNewCopy*: proc (dest: var GodotPoolByteArray,
                                 src: GodotPoolByteArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayNewWithArray*: proc (dest: var GodotPoolByteArray,
                                      src: GodotArray)
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    poolByteArrayAppend*: proc (self: var GodotPoolByteArray,
                                val: byte)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayAppendArray*: proc (self: var GodotPoolByteArray,
                                     arr: GodotPoolByteArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolByteArrayInsert*: proc (self: var GodotPoolByteArray,
                                idx: cint, val: byte): Error
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayInvert*: proc (self: var GodotPoolByteArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayPushBack*: proc (self: var GodotPoolByteArray, val: byte)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolByteArrayRemove*: proc (self: var GodotPoolByteArray, idx: cint)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayResize*: proc (self: var GodotPoolByteArray, size: cint)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayRead*: proc (self: GodotPoolByteArray): ptr GodotPoolByteArrayReadAccess
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWrite*: proc (self: var GodotPoolByteArray): ptr GodotPoolByteArrayWriteAccess
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArraySet*: proc (self: var GodotPoolByteArray, idx: cint, data: byte)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayGet*: proc (self: GodotPoolByteArray, idx: cint): byte
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArraySize*: proc (self: GodotPoolByteArray): cint
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayDestroy*: proc (self: GodotPoolByteArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolIntArray API
    poolIntArrayNew*: proc (dest: var GodotPoolIntArray)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayNewCopy*: proc (dest: var GodotPoolIntArray,
                                src: GodotPoolIntArray)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayNewWithArray*: proc (dest: var GodotPoolIntArray, src: GodotArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolIntArrayAppend*: proc (self: var GodotPoolIntArray, val: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayAppendArray*: proc (self: var GodotPoolIntArray,
                                    arr: GodotPoolIntArray)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    poolIntArrayInsert*: proc (self: var GodotPoolIntArray, idx: cint,
                               val: cint): Error
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayInvert*: proc (self: var GodotPoolIntArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayPushBack*: proc (self: var GodotPoolIntArray, val: cint)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayRemove*: proc (self: var GodotPoolIntArray, idx: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayResize*: proc (self: var GodotPoolIntArray, size: cint)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayRead*: proc (self: GodotPoolIntArray): ptr GodotPoolIntArrayReadAccess
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWrite*: proc (self: var GodotPoolIntArray): ptr GodotPoolIntArrayWriteAccess
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArraySet*: proc (self: var GodotPoolIntArray, idx: cint, data: cint)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayGet*: proc (self: GodotPoolIntArray, idx: cint): cint
                           {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArraySize*: proc (self: GodotPoolIntArray): cint
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayDestroy*: proc (self: GodotPoolIntArray)
                               {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolRealArray API
    poolRealArrayNew*: proc (dest: var GodotPoolRealArray)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayNewCopy*: proc (dest: var GodotPoolRealArray,
                                 src: GodotPoolRealArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayNewWithArray*: proc (dest: var GodotPoolRealArray,
                                      src: GodotArray)
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    poolRealArrayAppend*: proc (self: var GodotPoolRealArray, val: float32)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayAppendArray*: proc (self: var GodotPoolRealArray,
                                     arr: GodotPoolRealArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolRealArrayInsert*: proc (self: var GodotPoolRealArray,
                                idx: cint, val: float32): Error
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayInvert*: proc (self: var GodotPoolRealArray)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayPushBack*: proc (self: var GodotPoolRealArray, val: float32)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolRealArrayRemove*: proc (self: var GodotPoolRealArray, idx: cint)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayResize*: proc (self: var GodotPoolRealArray, size: cint)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayRead*: proc (self: GodotPoolRealArray): ptr GodotPoolRealArrayReadAccess
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWrite*: proc (self: var GodotPoolRealArray): ptr GodotPoolRealArrayWriteAccess
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArraySet*: proc (self: var GodotPoolRealArray, idx: cint,
                             data: float32)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayGet*: proc (self: GodotPoolRealArray, idx: cint): float32
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArraySize*: proc (self: GodotPoolRealArray): cint
                            {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayDestroy*: proc (self: GodotPoolRealArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}

    # PoolStringArray API
    poolStringArrayNew*: proc (dest: var GodotPoolStringArray)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayNewCopy*: proc (dest: var GodotPoolStringArray,
                                   src: GodotPoolStringArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolStringArrayNewWithArray*: proc (dest: var GodotPoolStringArray,
                                        src: GodotArray)
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    poolStringArrayAppend*: proc (self: var GodotPoolStringArray,
                                  val: GodotString)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolStringArrayAppendArray*: proc (self: var GodotPoolStringArray,
                                       arr: GodotPoolStringArray)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolStringArrayInsert*: proc (self: var GodotPoolStringArray,
                                  idx: cint, val: GodotString): Error
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolStringArrayInvert*: proc (self: var GodotPoolStringArray)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolStringArrayPushBack*: proc (self: var GodotPoolStringArray,
                                    val: GodotString)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    poolStringArrayRemove*: proc (self: var GodotPoolStringArray, idx: cint)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolStringArrayResize*: proc (self: var GodotPoolStringArray, size: cint)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolStringArrayRead*: proc (self: GodotPoolStringArray): ptr GodotPoolStringArrayReadAccess
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWrite*: proc (self: var GodotPoolStringArray): ptr GodotPoolStringArrayWriteAccess
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArraySet*: proc (self: var GodotPoolStringArray, idx: cint,
                               data: GodotString)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayGet*: proc (self: GodotPoolStringArray, idx: cint): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArraySize*: proc (self: GodotPoolStringArray): cint
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayDestroy*: proc (self: GodotPoolStringArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # PoolVector2 API
    poolVector2ArrayNew*: proc (dest: var GodotPoolVector2Array)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayNewCopy*: proc (dest: var GodotPoolVector2Array,
                                    src: GodotPoolVector2Array)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    poolVector2ArrayNewWithArray*: proc (dest: var GodotPoolVector2Array,
                                         src: GodotArray)
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    poolVector2ArrayAppend*: proc (self: var GodotPoolVector2Array, val: Vector2)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayAppendArray*: proc (self: var GodotPoolVector2Array,
                                        arr: GodotPoolVector2Array)
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    poolVector2ArrayInsert*: proc (self: var GodotPoolVector2Array, idx: cint,
                                   val: Vector2): Error
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayInvert*: proc (self: var GodotPoolVector2Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayPushBack*: proc (self: var GodotPoolVector2Array,
                                     val: Vector2)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    poolVector2ArrayRemove*: proc (self: var GodotPoolVector2Array, idx: cint)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayResize*: proc (self: var GodotPoolVector2Array, size: cint)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector2ArrayRead*: proc (self: GodotPoolVector2Array): ptr GodotPoolVector2ArrayReadAccess
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWrite*: proc (self: var GodotPoolVector2Array): ptr GodotPoolVector2ArrayWriteAccess
                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArraySet*: proc (self: var GodotPoolVector2Array, idx: cint,
                                data: Vector2)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayGet*: proc (self: GodotPoolVector2Array, idx: cint): Vector2Data
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArraySize*: proc (self: GodotPoolVector2Array): cint
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayDestroy*: proc (self: GodotPoolVector2Array)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}

    # PoolVector3 API
    poolVector3ArrayNew*: proc (dest: var GodotPoolVector3Array)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayNewCopy*: proc (dest: var GodotPoolVector3Array,
                                    src: GodotPoolVector3Array)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    poolVector3ArrayNewWithArray*: proc (dest: var GodotPoolVector3Array,
                                         src: GodotArray)
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    poolVector3ArrayAppend*: proc (self: var GodotPoolVector3Array, val: Vector3)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayAppendArray*: proc (self: var GodotPoolVector3Array,
                                        arr: GodotPoolVector3Array)
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    poolVector3ArrayInsert*: proc (self: var GodotPoolVector3Array, idx: cint,
                                   val: Vector3): Error
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayInvert*: proc (self: var GodotPoolVector3Array)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolVector3ArrayPushBack*: proc (self: var GodotPoolVector3Array,
                                     val: Vector3) {.noconv, raises: [], gcsafe,
                                                    tags: [], .}
    poolVector3ArrayRemove*: proc (self: var GodotPoolVector3Array,
                                  idx: cint) {.noconv, raises: [], gcsafe,
                                                tags: [], .}
    poolVector3ArrayResize*: proc (self: var GodotPoolVector3Array,
                                   size: cint) {.noconv, raises: [], gcsafe,
                                                tags: [], .}
    poolVector3ArrayRead*: proc (self: GodotPoolVector3Array): ptr GodotPoolVector3ArrayReadAccess
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWrite*: proc (self: var GodotPoolVector3Array): ptr GodotPoolVector3ArrayWriteAccess
                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArraySet*: proc (self: var GodotPoolVector3Array, idx: cint,
                                data: Vector3) {.noconv, raises: [], gcsafe,
                                                tags: [], .}
    poolVector3ArrayGet*: proc (self: GodotPoolVector3Array, idx: cint): Vector3Data
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArraySize*: proc (self: GodotPoolVector3Array): cint
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayDestroy*: proc (self: GodotPoolVector3Array)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # PoolColorArray API
    poolColorArrayNew*: proc (dest: var GodotPoolColorArray)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayNewCopy*: proc (dest: var GodotPoolColorArray,
                                  src: GodotPoolColorArray)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    poolColorArrayNewWithArray*: proc (dest: var GodotPoolColorArray,
                                       src: GodotArray)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    poolColorArrayAppend*: proc (self: var GodotPoolColorArray,
                                 val: Color)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayAppendArray*: proc (self: var GodotPoolColorArray,
                                      arr: GodotPoolColorArray)
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    poolColorArrayInsert*: proc (self: var GodotPoolColorArray,
                                 idx: cint, val: Color): Error
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayInvert*: proc (self: var GodotPoolColorArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayPushBack*: proc (self: var GodotPoolColorArray, val: Color)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    poolColorArrayRemove*: proc (self: var GodotPoolColorArray, idx: cint)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayResize*: proc (self: var GodotPoolColorArray, size: cint)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayRead*: proc (self: GodotPoolColorArray): ptr GodotPoolColorArrayReadAccess
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWrite*: proc (self: var GodotPoolColorArray): ptr GodotPoolColorArrayWriteAccess
                               {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArraySet*: proc (self: var GodotPoolColorArray, idx: cint,
                              data: Color)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayGet*: proc (self: GodotPoolColorArray, idx: cint): ColorData
                             {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArraySize*: proc (self: GodotPoolColorArray): cint
                              {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayDestroy*: proc (self: GodotPoolColorArray)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}

    # Pool Array Read/Write Access API

    poolByteArrayReadAccessCopy*: proc (self: ptr GodotPoolByteArrayReadAccess): ptr GodotPoolByteArrayReadAccess
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayReadAccessPtr*: proc (self: ptr GodotPoolByteArrayReadAccess): ptr byte
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolByteArrayReadAccess)
                                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayReadAccessDestroy*: proc (self: ptr GodotPoolByteArrayReadAccess)
                                          {.noconv, raises: [], gcsafe, tags: [], .}

    poolIntArrayReadAccessCopy*: proc (self: ptr GodotPoolIntArrayReadAccess): ptr GodotPoolIntArrayReadAccess
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayReadAccessPtr*: proc (self: ptr GodotPoolIntArrayReadAccess): ptr cint
                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolIntArrayReadAccess)
                                                {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayReadAccessDestroy*: proc (self: ptr GodotPoolIntArrayReadAccess)
                                         {.noconv, raises: [], gcsafe, tags: [], .}

    poolRealArrayReadAccessCopy*: proc (self: ptr GodotPoolRealArrayReadAccess): ptr GodotPoolRealArrayReadAccess
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayReadAccessPtr*: proc (self: ptr GodotPoolRealArrayReadAccess): ptr float32
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolRealArrayReadAccess)
                                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayReadAccessDestroy*: proc (self: ptr GodotPoolRealArrayReadAccess)
                                          {.noconv, raises: [], gcsafe, tags: [], .}

    poolStringArrayReadAccessCopy*: proc (self: ptr GodotPoolStringArrayReadAccess): ptr GodotPoolStringArrayReadAccess
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayReadAccessPtr*: proc (self: ptr GodotPoolStringArrayReadAccess): ptr GodotString
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolStringArrayReadAccess)
                                                   {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayReadAccessDestroy*: proc (self: ptr GodotPoolStringArrayReadAccess)
                                            {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector2ArrayReadAccessCopy*: proc (self: ptr GodotPoolVector2ArrayReadAccess): ptr GodotPoolVector2ArrayReadAccess
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayReadAccessPtr*: proc (self: ptr GodotPoolVector2ArrayReadAccess): ptr Vector2
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolVector2ArrayReadAccess)
                                                    {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayReadAccessDestroy*: proc (self: ptr GodotPoolVector2ArrayReadAccess)
                                             {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector3ArrayReadAccessCopy*: proc (self: ptr GodotPoolVector3ArrayReadAccess): ptr GodotPoolVector3ArrayReadAccess
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayReadAccessPtr*: proc (self: ptr GodotPoolVector3ArrayReadAccess): ptr Vector3
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolVector3ArrayReadAccess)
                                                    {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayReadAccessDestroy*: proc (self: ptr GodotPoolVector3ArrayReadAccess)
                                             {.noconv, raises: [], gcsafe, tags: [], .}

    poolColorArrayReadAccessCopy*: proc (self: ptr GodotPoolColorArrayReadAccess): ptr GodotPoolColorArrayReadAccess
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayReadAccessPtr*: proc (self: ptr GodotPoolColorArrayReadAccess): ptr Color
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayReadAccessOperatorAssign*: proc (self, other: ptr GodotPoolColorArrayReadAccess)
                                                  {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayReadAccessDestroy*: proc (self: ptr GodotPoolColorArrayReadAccess)
                                           {.noconv, raises: [], gcsafe, tags: [], .}

    poolByteArrayWriteAccessCopy*: proc (self: ptr GodotPoolByteArrayWriteAccess): ptr GodotPoolByteArrayWriteAccess
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWriteAccessPtr*: proc (self: ptr GodotPoolByteArrayWriteAccess): ptr byte
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolByteArrayWriteAccess)
                                                  {.noconv, raises: [], gcsafe, tags: [], .}
    poolByteArrayWriteAccessDestroy*: proc (self: ptr GodotPoolByteArrayWriteAccess)
                                           {.noconv, raises: [], gcsafe, tags: [], .}

    poolIntArrayWriteAccessCopy*: proc (self: ptr GodotPoolIntArrayWriteAccess): ptr GodotPoolIntArrayWriteAccess
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWriteAccessPtr*: proc (self: ptr GodotPoolIntArrayWriteAccess): ptr cint
                                      {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolIntArrayWriteAccess)
                                                 {.noconv, raises: [], gcsafe, tags: [], .}
    poolIntArrayWriteAccessDestroy*: proc (self: ptr GodotPoolIntArrayWriteAccess)
                                          {.noconv, raises: [], gcsafe, tags: [], .}

    poolRealArrayWriteAccessCopy*: proc (self: ptr GodotPoolRealArrayWriteAccess): ptr GodotPoolRealArrayWriteAccess
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWriteAccessPtr*: proc (self: ptr GodotPoolRealArrayWriteAccess): ptr float32
                                       {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolRealArrayWriteAccess)
                                                  {.noconv, raises: [], gcsafe, tags: [], .}
    poolRealArrayWriteAccessDestroy*: proc (self: ptr GodotPoolRealArrayWriteAccess)
                                           {.noconv, raises: [], gcsafe, tags: [], .}

    poolStringArrayWriteAccessCopy*: proc (self: ptr GodotPoolStringArrayWriteAccess): ptr GodotPoolStringArrayWriteAccess
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWriteAccessPtr*: proc (self: ptr GodotPoolStringArrayWriteAccess): ptr GodotString
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolStringArrayWriteAccess)
                                                    {.noconv, raises: [], gcsafe, tags: [], .}
    poolStringArrayWriteAccessDestroy*: proc (self: ptr GodotPoolStringArrayWriteAccess)
                                             {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector2ArrayWriteAccessCopy*: proc (self: ptr GodotPoolVector2ArrayWriteAccess): ptr GodotPoolVector2ArrayWriteAccess
                                           {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWriteAccessPtr*: proc (self: ptr GodotPoolVector2ArrayWriteAccess): ptr Vector2
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolVector2ArrayWriteAccess)
                                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector2ArrayWriteAccessDestroy*: proc (self: ptr GodotPoolVector2ArrayWriteAccess)
                                              {.noconv, raises: [], gcsafe, tags: [], .}

    poolVector3ArrayWriteAccessCopy*: proc (self: ptr GodotPoolVector3ArrayWriteAccess): ptr GodotPoolVector3ArrayWriteAccess
                                           {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWriteAccessPtr*: proc (self: ptr GodotPoolVector3ArrayWriteAccess): ptr Vector3
                                          {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolVector3ArrayWriteAccess)
                                                     {.noconv, raises: [], gcsafe, tags: [], .}
    poolVector3ArrayWriteAccessDestroy*: proc (self: ptr GodotPoolVector3ArrayWriteAccess)
                                              {.noconv, raises: [], gcsafe, tags: [], .}

    poolColorArrayWriteAccessCopy*: proc (self: ptr GodotPoolColorArrayWriteAccess): ptr GodotPoolColorArrayWriteAccess
                                         {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWriteAccessPtr*: proc (self: ptr GodotPoolColorArrayWriteAccess): ptr Color
                                        {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWriteAccessOperatorAssign*: proc (self, other: ptr GodotPoolColorArrayWriteAccess)
                                                   {.noconv, raises: [], gcsafe, tags: [], .}
    poolColorArrayWriteAccessDestroy*: proc (self: ptr GodotPoolColorArrayWriteAccess)
                                            {.noconv, raises: [], gcsafe, tags: [], .}

    # Array API
    arrayNew*: proc (dest: var GodotArray)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayNewCopy*: proc (dest: var GodotArray, src: GodotArray)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayNewPoolColorArray*: proc (dest: var GodotArray, src: GodotPoolColorArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    arrayNewPoolVector3Array*: proc (dest: var GodotArray,
                                     src: GodotPoolVector3Array)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    arrayNewPoolVector2Array*: proc (dest: var GodotArray,
                                     src: GodotPoolVector2Array)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    arrayNewPoolStringArray*: proc (dest: var GodotArray,
                                    src: GodotPoolStringArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    arrayNewPoolRealArray*: proc (dest: var GodotArray, src: GodotPoolRealArray)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    arrayNewPoolIntArray*: proc (dest: var GodotArray, src: GodotPoolIntArray)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    arrayNewPoolByteArray*: proc (dest: var GodotArray, src: GodotPoolByteArray)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    arraySet*: proc (self: var GodotArray, idx: cint, val: GodotVariant)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayGet*: proc (self: GodotArray, idx: cint): GodotVariant
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayOperatorIndex*: proc (self: var GodotArray, idx: cint): ptr GodotVariant
                              {.noconv, raises: [], gcsafe, tags: [], .}
    arrayAppend*: proc (self: var GodotArray, val: GodotVariant)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayClear*: proc (self: var GodotArray)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayCount*: proc (self: GodotArray, val: GodotVariant): cint
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayEmpty*: proc (self: GodotArray): bool
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayErase*: proc (self: var GodotArray, val: GodotVariant)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayFront*: proc (self: GodotArray): GodotVariant
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arrayBack*: proc (self: GodotArray): GodotVariant
                     {.noconv, raises: [], gcsafe, tags: [], .}
    arrayFind*: proc (self: GodotArray, what: GodotVariant, fromIdx: cint): cint
                     {.noconv, raises: [], gcsafe, tags: [], .}
    arrayFindLast*: proc (self: GodotArray, what: GodotVariant): cint
                         {.noconv, raises: [], gcsafe, tags: [], .}
    arrayHas*: proc (self: GodotArray, val: GodotVariant): bool
                    {.noconv, raises: [], gcsafe, tags: [], .}
    arrayHash*: proc (self: GodotArray): cint
                     {.noconv, raises: [], gcsafe, tags: [], .}
    arrayInsert*: proc (self: var GodotArray, pos: cint, val: GodotVariant): Error
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayInvert*: proc (self: var GodotArray)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPopFront*: proc (self: GodotArray): GodotVariant
                         {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPopBack*: proc (self: GodotArray): GodotVariant
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPushBack*: proc (self: var GodotArray, val: GodotVariant)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    arrayPushFront*: proc (self: var GodotArray, val: GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    arrayRemove*: proc (self: var GodotArray, idx: cint)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayResize*: proc (self: var GodotArray, size: cint)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    arrayRFind*: proc (self: GodotArray, what: GodotVariant, fromIdx: cint): cint
                      {.noconv, raises: [], gcsafe, tags: [], .}
    arraySize*: proc (self: GodotArray): cint
                     {.noconv, raises: [], gcsafe, tags: [], .}
    arraySort*: proc (self: var GodotArray)
                     {.noconv, raises: [], gcsafe, tags: [], .}
    arraySortCustom*: proc (self: var GodotArray, obj: ptr GodotObject,
                            f: GodotString)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    arrayBSearch*: proc (self: var GodotArray, val: ptr GodotVariant,
                         before: bool)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    arrayBSearchCustom*: proc (self: var GodotArray, val: ptr GodotVariant,
                               obj: ptr GodotObject, f: GodotString,
                               before: bool)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    arrayDestroy*: proc (self: var GodotArray)
                        {.noconv, raises: [], gcsafe, tags: [], .}

    # Dictionary API
    dictionaryNew*: proc (dest: var GodotDictionary)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryNewCopy*: proc (dest: var GodotDictionary, src: GodotDictionary)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryDestroy*: proc (self: var GodotDictionary)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    dictionarySize*: proc (self: GodotDictionary): cint
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryEmpty*: proc (self: GodotDictionary): bool
                           {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryClear*: proc (self: var GodotDictionary)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryHas*: proc (self: GodotDictionary, key: GodotVariant): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryHasAll*: proc (self: GodotDictionary, keys: GodotArray): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryErase*: proc (self: var GodotDictionary, key: GodotVariant)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryHash*: proc (self: GodotDictionary): cint
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryKeys*: proc (self: GodotDictionary): GodotArray
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryValues*: proc (self: GodotDictionary): GodotArray
                            {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryGet*: proc (self: GodotDictionary, key: GodotVariant): GodotVariant
                         {.noconv, raises: [], gcsafe, tags: [], .}
    dictionarySet*: proc (self: var GodotDictionary, key, value: GodotVariant)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryOperatorIndex*: proc (self: var GodotDictionary,
                                    key: GodotVariant): ptr GodotVariant
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    dictionaryNext*: proc (self: GodotDictionary,
                           key: GodotVariant): ptr GodotVariant
                          {.noconv, raises: [], gcsafe, tags: [], .}
    dictionaryOperatorEqual*: proc (self, other: GodotDictionary): bool
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    dictionaryToJson*: proc (self: GodotDictionary): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}

    # NodePath API
    nodePathNew*: proc (dest: var GodotNodePath, src: GodotString)
                       {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathNewCopy*: proc (dest: var GodotNodePath, src: GodotNodePath)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathDestroy*: proc (self: var GodotNodePath)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathAsString*: proc (self: GodotNodePath): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathIsAbsolute*: proc (self: GodotNodePath): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetNameCount*: proc (self: GodotNodePath): cint
                                {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetName*: proc (self: GodotNodePath, idx: cint): GodotString
                           {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetSubnameCount*: proc (self: GodotNodePath): cint
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    nodePathGetSubname*: proc (self: GodotNodePath, idx: cint): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathGetConcatenatedSubnames*: proc (self: GodotNodePath): GodotString
                                           {.noconv, raises: [], gcsafe,
                                             tags: [], .}
    nodePathIsEmpty*: proc (self: GodotNodePath): bool
                           {.noconv, raises: [], gcsafe, tags: [], .}
    nodePathOperatorEqual*: proc (self, other: GodotNodePath): bool
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}

    # Plane API
    planeNewWithReals*: proc (dest: var Plane, a, b, c, d: float32)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    planeNewWithVectors*: proc (dest: var Plane, v1, v2, v3: Vector3)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    planeNewWithNormal*: proc (dest: var Plane, normal: Vector3, d: float32)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeAsString*: proc (self: Plane): GodotString
                         {.noconv, raises: [], gcsafe, tags: [], .}
    planeNormalized*: proc (self: Plane): PlaneData
                           {.noconv, raises: [], gcsafe, tags: [], .}
    planeCenter*: proc (self: Plane): Vector3Data
                       {.noconv, raises: [], gcsafe, tags: [], .}
    planeGetAnyPoint*: proc (self: Plane): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeIsPointOver*: proc (self: Plane, point: Vector3): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeDistanceTo*: proc (self: Plane, point: Vector3): float32
                           {.noconv, raises: [], gcsafe, tags: [], .}
    planeHasPoint*: proc (self: Plane, point: Vector3, epsilon: float32): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    planeProject*: proc (self: Plane, point: Vector3): Vector3Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    planeIntersect3*: proc (self: Plane, dest: var Vector3, b, c: Plane): bool
                           {.noconv, raises: [], gcsafe, tags: [], .}
    planeIntersectsRay*: proc (self: Plane, dest: var Vector3,
                               point, dir: Vector3): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeIntersectsSegment*: proc (self: Plane, dest: var Vector3,
                                   segmentBegin, segmentEnd: Vector3): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    planeOperatorNeg*: proc (self: Plane): PlaneData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    planeOperatorEqual*: proc (self, other: Plane): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    planeSetNormal*: proc (self: var Plane, normal: Vector3)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeGetNormal*: proc (self: Plane): Vector3Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    planeGetD*: proc (self: Plane): float32
                    {.noconv, raises: [], gcsafe, tags: [], .}
    planeSetD*: proc (self: var Plane, d: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}

    # Rect2 API
    rect2NewWithPositionAndSize*: proc (dest: var Rect2, pos, size: Vector2)
                                       {.noconv, raises: [], gcsafe, tags: [],
                                         .}
    rect2New*: proc (dest: var Rect2, x, y, width, height: float32)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    rect2AsString*: proc (self: Rect2): GodotString
                         {.noconv, raises: [], gcsafe, tags: [], .}
    rect2GetArea*: proc (self: Rect2): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Intersects*: proc (self, other: Rect2): bool
                           {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Encloses*: proc (self, other: Rect2): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    rect2HasNoArea*: proc (self: Rect2): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Clip*: proc (self, other: Rect2): Rect2Data
                     {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Merge*: proc (self, other: Rect2): Rect2Data
                      {.noconv, raises: [], gcsafe, tags: [], .}
    rect2HasPoint*: proc (self: Rect2, point: Vector2): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Grow*: proc (self: Rect2, by: float32): Rect2Data
                     {.noconv, raises: [], gcsafe, tags: [], .}
    rect2Expand*: proc (self: Rect2, to: Vector2): Rect2Data
                       {.noconv, raises: [], gcsafe, tags: [], .}
    rect2OperatorEqual*: proc (self, other: Rect2): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    rect2GetPosition*: proc (self: Rect2): Vector2Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    rect2GetSize*: proc (self: Rect2): Vector2Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    rect2SetPosition*: proc (self: var Rect2, pos: Vector2)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    rect2SetSize*: proc (self: var Rect2, size: Vector2)
                        {.noconv, raises: [], gcsafe, tags: [], .}

    # AABB API
    aabbNew*: proc (dest: var AABB, pos, size: Vector3)
                    {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetPosition*: proc (self: AABB): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbSetPosition*: proc (self: var AABB, pos: Vector3)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetSize*: proc (self: AABB): Vector3Data
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbSetSize*: proc (self: var AABB, pos: Vector3)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbAsString*: proc (self: AABB): GodotString
                         {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetArea*: proc (self: AABB): float32
                        {.noconv, raises: [], gcsafe, tags: [], .}
    aabbHasNoArea*: proc (self: AABB): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}
    aabbHasNoSurface*: proc (self: AABB): bool
                             {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersects*: proc (self, other: AABB): bool
                           {.noconv, raises: [], gcsafe, tags: [], .}
    aabbEncloses*: proc (self, other: AABB): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    aabbMerge*: proc (self, other: AABB): AABBData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersection*: proc (self, other: AABB): AABBData
                             {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersectsPlane*: proc (self: AABB, plane: Plane): bool
                                {.noconv, raises: [], gcsafe, tags: [], .}
    aabbIntersectsSegment*: proc (self: AABB, vFrom, vTo: Vector3): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    aabbHasPoint*: proc (self: AABB, point: Vector3): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetSupport*: proc (self: AABB, dir: Vector3): Vector3Data
                           {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetLongestAxis*: proc (self: AABB): Vector3Data
                               {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetLongestAxisIndex*: proc (self: AABB): cint
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    aabbGetLongestAxisSize*: proc (self: AABB): float32
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    aabbGetShortestAxis*: proc (self: AABB): Vector3Data
                                {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetShortestAxisIndex*: proc (self: AABB): cint
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    aabbGetShortestAxisSize*: proc (self: AABB): float32
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    aabbExpand*: proc (self: AABB, toPoint: Vector3): AABBData
                      {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGrow*: proc (self: AABB, by: float32): AABBData
                    {.noconv, raises: [], gcsafe, tags: [], .}
    aabbGetEndpoint*: proc (self: AABB, idx: cint): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    aabbOperatorEqual*: proc (self, other: AABB): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}

    # RID API
    ridNew*: proc (dest: var RID)
                  {.noconv, raises: [], gcsafe, tags: [], .}
    ridGetID*: proc (self: RID): cint
                    {.noconv, raises: [], gcsafe, tags: [], .}
    ridNewWithResource*: proc (dest: var RID, obj: ptr GodotObject)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    ridOperatorEqual*: proc (self, other: RID): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    ridOperatorLess*: proc (self, other: RID): bool
                          {.noconv, raises: [], gcsafe, tags: [], .}

    # Transform API
    transformNewWithAxisOrigin*: proc (dest: var Transform,
                                       xAxis, yAxis, zAxis, origin: Vector3)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transformNew*: proc (dest: var Transform, basis: Basis, origin: Vector3)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    transformGetBasis*: proc (self: Transform): BasisData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformSetBasis*: proc (self: var Transform, basis: Basis)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformGetOrigin*: proc (self: Transform): Vector3Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformSetOrigin*: proc (self: var Transform, v: Vector3)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformAsString*: proc (self: Transform): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformInverse*: proc (self: Transform): TransformData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformAffineInverse*: proc (self: Transform): TransformData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transformOrthonormalized*: proc (self: Transform): TransformData
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transformRotated*: proc (self: Transform, axis: Vector3,
                             phi: float32): TransformData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transformScaled*: proc (self: Transform, scale: Vector3): TransformData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    transformTranslated*: proc (self: Transform, offset: Vector3): TransformData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformLookingAt*: proc (self: Transform, target, up: Vector3): TransformData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformXformPlane*: proc (self: Transform, plane: Plane): PlaneData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformXformInvPlane*: proc (self: Transform, plane: Plane): PlaneData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transformNewIdentity*: proc (dest: var Transform)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    transformOperatorEqual*: proc (self, other: Transform): bool
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transformOperatorMultiply*: proc (self, other: Transform): TransformData
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transformXformVector3*: proc (self: Transform, v: Vector3): Vector3Data
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    transformXformInvVector3*: proc (self: Transform, v: Vector3): Vector3Data
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transformXformAABB*: proc (self: Transform, v: AABB): AABBData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transformXformInvAABB*: proc (self: Transform, v: AABB): AABBData
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}

    # Transform2D API
    transform2DNew*: proc (dest: var Transform2D, rot: float32, pos: Vector2)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DNewAxisOrigin*: proc (dest: var Transform2D,
                                     xAxis, yAxis, origin: Vector2)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transform2DAsString*: proc (self: Transform2D): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DInverse*: proc (self: Transform2D): Transform2DData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DAffineInverse*: proc (self: Transform2D): Transform2DData
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transform2DGetRotation*: proc (self: Transform2D): float32
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transform2DGetOrigin*: proc (self: Transform2D): Vector2Data
                                {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DGetScale*: proc (self: Transform2D): Vector2Data
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DOrthonormalized*: proc (self: Transform2D): Transform2DData
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DRotated*: proc (self: Transform2D, phi: float32): Transform2DData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DScaled*: proc (self: Transform2D, scale: Vector2): Transform2DData
                            {.noconv, raises: [], gcsafe, tags: [], .}
    transform2DTranslated*: proc (self: Transform2D, offset: Vector2): Transform2DData
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    transform2DXformVector2*: proc (self: Transform2D, v: Vector2): Vector2Data
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transform2DXformInvVector2*: proc (self: Transform2D, v: Vector2): Vector2Data
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DBasisXformVector2*: proc (self: Transform2D, v: Vector2): Vector2Data
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    transform2DBasisXformInvVector2*: proc (self: Transform2D,
                                            v: Vector2): Vector2Data
                                          {.noconv, raises: [], gcsafe, tags: [],
                                            .}
    transform2DInterpolateWith*: proc (self, other: Transform2D,
                                      t: float32): Transform2DData
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DOperatorEqual*: proc (self, other: Transform2D): bool
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    transform2DOperatorMultiply*: proc (self, other: Transform2D): Transform2DData
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    transform2DNewIdentity*: proc (dest: var Transform2D)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    transform2DXformRect2*: proc (self: Transform2D, v: Rect2): Rect2Data
                                {.noconv, raises: [], gcsafe, tags: [],
                                  .}
    transform2DXformInvRect2*: proc (self: Transform2D, v: Rect2): Rect2Data
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}

    # Variant API
    variantGetType*: proc (v: GodotVariant): VariantType
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewCopy*: proc (dest: var GodotVariant, src: GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewNil*: proc (dest: var GodotVariant)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewBool*: proc (dest: var GodotVariant, val: bool)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewUInt*: proc (dest: var GodotVariant, val: uint64)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewInt*: proc (dest: var GodotVariant, val: int64)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewReal*: proc (dest: var GodotVariant, val: float64)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewString*: proc (dest: var GodotVariant, val: GodotString)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewVector2*: proc (dest: var GodotVariant, val: Vector2)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewRect2*: proc (dest: var GodotVariant, val: Rect2)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewVector3*: proc (dest: var GodotVariant, val: Vector3)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewTransform2D*: proc (dest: var GodotVariant, val: Transform2D)
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    variantNewPlane*: proc (dest: var GodotVariant, val: Plane)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewQuat*: proc (dest: var GodotVariant, val: Quat)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewAABB*: proc (dest: var GodotVariant, val: AABB)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewBasis*: proc (dest: var GodotVariant, val: Basis)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewTransform*: proc (dest: var GodotVariant, val: Transform)
                               {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewColor*: proc (dest: var GodotVariant, val: Color)
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewNodePath*: proc (dest: var GodotVariant, val: GodotNodePath)
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewRID*: proc (dest: var GodotVariant, val: RID)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewObject*: proc (dest: var GodotVariant, val: ptr GodotObject)
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewDictionary*: proc (dest: var GodotVariant, val: GodotDictionary)
                                {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewArray*: proc (dest: var GodotVariant, val: GodotArray)
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantNewPoolByteArray*: proc (dest: var GodotVariant,
                                    val: GodotPoolByteArray)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    variantNewPoolIntArray*: proc (dest: var GodotVariant, val: GodotPoolIntArray)
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantNewPoolRealArray*: proc (dest: var GodotVariant,
                                    val: GodotPoolRealArray)
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    variantNewPoolStringArray*: proc (dest: var GodotVariant,
                                      val: GodotPoolStringArray)
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    variantNewPoolVector2Array*: proc (dest: var GodotVariant,
                                       val: GodotPoolVector2Array)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    variantNewPoolVector3Array*: proc (dest: var GodotVariant,
                                       val: GodotPoolVector3Array)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    variantNewPoolColorArray*: proc (dest: var GodotVariant,
                                     val: GodotPoolColorArray)
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantAsBool*: proc (self: GodotVariant): bool
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsUInt*: proc (self: GodotVariant): uint64
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsInt*: proc (self: GodotVariant): int64
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsReal*: proc (self: GodotVariant): float64
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsString*: proc (self: GodotVariant): GodotString
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsVector2*: proc (self: GodotVariant): Vector2Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsRect2*: proc (self: GodotVariant): Rect2Data
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsVector3*: proc (self: GodotVariant): Vector3Data
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsTransform2D*: proc (self: GodotVariant): Transform2DData
                                {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsPlane*: proc (self: GodotVariant): PlaneData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsQuat*: proc (self: GodotVariant): QuatData
                         {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsAABB*: proc (self: GodotVariant): AABBData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsBasis*: proc (self: GodotVariant): BasisData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsTransform*: proc (self: GodotVariant): TransformData
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsColor*: proc (self: GodotVariant): ColorData
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsNodePath*: proc (self: GodotVariant): GodotNodePath
                             {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsRID*: proc (self: GodotVariant): RID
                        {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsObject*: proc (self: GodotVariant): ptr GodotObject
                           {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsDictionary*: proc (self: GodotVariant): GodotDictionary
                               {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsArray*: proc (self: GodotVariant): GodotArray
                          {.noconv, raises: [], gcsafe, tags: [], .}
    variantAsPoolByteArray*: proc (self: GodotVariant): GodotPoolByteArray
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantAsPoolIntArray*: proc (self: GodotVariant): GodotPoolIntArray
                                 {.noconv, raises: [], gcsafe, tags: [],
                                   .}
    variantAsPoolRealArray*: proc (self: GodotVariant): GodotPoolRealArray
                                  {.noconv, raises: [], gcsafe, tags: [],
                                    .}
    variantAsPoolStringArray*: proc (self: GodotVariant): GodotPoolStringArray
                                    {.noconv, raises: [], gcsafe, tags: [],
                                      .}
    variantAsPoolVector2Array*: proc (self: GodotVariant): GodotPoolVector2Array
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    variantAsPoolVector3Array*: proc (self: GodotVariant): GodotPoolVector3Array
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    variantAsPoolColorArray*: proc (self: GodotVariant): GodotPoolColorArray
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}
    variantCall*: proc (self: var GodotVariant, meth: GodotString,
                        args: ptr array[MAX_ARG_COUNT, ptr GodotVariant],
                        argcount: cint,
                        callError: var VariantCallError): GodotVariant
                      {.noconv, raises: [], gcsafe, tags: [], .}
    variantHasMethod*: proc (self: GodotVariant, meth: GodotString): bool
                            {.noconv, raises: [], gcsafe, tags: [], .}
    variantOperatorEqual*: proc (self, other: GodotVariant): bool
                                {.noconv, raises: [], gcsafe, tags: [], .}
    variantOperatorLess*: proc (self, other: GodotVariant): bool
                               {.noconv, raises: [], gcsafe, tags: [], .}
    variantHashCompare*: proc (self, other: GodotVariant): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    variantBooleanize*: proc (self: GodotVariant): bool
                             {.noconv, raises: [], gcsafe, tags: [], .}
    variantDestroy*: proc (self: var GodotVariant)
                          {.noconv, raises: [], gcsafe, tags: [], .}

    # String API
    charStringLength*: proc (self: GodotCharString): cint
                            {.noconv, raises: [], gcsafe, tags: [], .}
    charStringGetData*: proc (self: GodotCharString): cstring
                             {.noconv, raises: [], gcsafe, tags: [], .}
    charStringDestroy*: proc (self: var GodotCharString)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    stringNew*: proc (dest: var GodotString)
                     {.noconv, raises: [], gcsafe, tags: [], .}
    stringNewCopy*: proc (dest: var GodotString, src: GodotString)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    stringWideStr*: proc (self: GodotString): ptr cwchar_t
                        {.noconv, raises: [], gcsafe, tags: [], .}
    stringOperatorEqual*: proc (self, other: GodotString): bool
                               {.noconv, raises: [], gcsafe, tags: [], .}
    stringOperatorLess*: proc (self, other: GodotString): bool
                              {.noconv, raises: [], gcsafe, tags: [], .}
    stringOperatorPlus*: proc (self, other: GodotString): GodotString
                              {.noconv, raises: [], gcsafe, tags: [], .}
    stringLength*: proc (self: GodotString): cint
                        {.noconv, raises: [], gcsafe, tags: [], .}
    stringDestroy*: proc (self: var GodotString)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    stringUtf8*: proc (self: GodotString): GodotCharString
                     {.noconv, raises: [], gcsafe, tags: [], .}
    stringCharsToUtf8*: proc (str: cstring): GodotString
                            {.noconv, raises: [], gcsafe, tags: [], .}
    stringCharsToUtf8WithLen*: proc (str: cstring, len: cint): GodotString
                                    {.noconv, raises: [], gcsafe, tags: [], .}

    # Misc API
    objectDestroy*: proc (self: ptr GodotObject)
                         {.noconv, raises: [], gcsafe, tags: [], .}
    globalGetSingleton*: proc (name: cstring): ptr GodotObject
                              {.noconv, raises: [], gcsafe, tags: [], .}
    methodBindGetMethod*: proc (className,
                                methodName: cstring): ptr GodotMethodBind
                               {.noconv, raises: [], gcsafe, tags: [], .}
    methodBindPtrCall*: proc (methodBind: ptr GodotMethodBind,
                              obj: ptr GodotObject,
                              args: ptr array[MAX_ARG_COUNT, pointer],
                              ret: pointer)
                             {.noconv, raises: [], gcsafe, tags: [], .}
    methodBindCall*: proc (methodBind: ptr GodotMethodBind, obj: ptr GodotObject,
                           args: ptr array[MAX_ARG_COUNT, ptr GodotVariant],
                           argCount: cint,
                           callError: var VariantCallError): GodotVariant
                          {.noconv, raises: [], gcsafe, tags: [], .}
    getClassConstructor*: proc (className: cstring): GodotClassConstructor
                               {.noconv, raises: [], gcsafe, tags: [], .}

    alloc*: proc (bytes: cint): pointer
                 {.noconv, raises: [], gcsafe, tags: [], .}
    realloc*: proc (p: pointer, bytes: cint): pointer
                   {.noconv, raises: [], gcsafe, tags: [], .}
    free*: proc (p: pointer) {.noconv, raises: [], gcsafe, tags: [], .}

    printError*: proc (description, function, file: cstring, line: cint)
                      {.noconv, raises: [], gcsafe, tags: [], .}
    printWarning*: proc (description, function, file: cstring, line: cint)
                        {.noconv, raises: [], gcsafe, tags: [], .}
    print*: proc (message: GodotString)
                 {.noconv, raises: [], gcsafe, tags: [], .}

    nativeScriptRegisterClass*: proc (gdnativeHandle: pointer,
                                      name, base: cstring,
                                      createFunc: GodotInstanceCreateFunc,
                                      destroyFunc: GodotInstanceDestroyFunc)
                                     {.noconv, raises: [], gcsafe, tags: [],
                                       .}
    nativeScriptRegisterToolClass*: proc (gdnativeHandle: pointer,
                                          name, base: cstring,
                                          createFunc: GodotInstanceCreateFunc,
                                          destroyFunc: GodotInstanceDestroyFunc)
                                         {.noconv, raises: [], gcsafe, tags: [],
                                           .}
    nativeScriptRegisterMethod*: proc (gdnativeHandle: pointer,
                                       name, functionName: cstring,
                                       attr: GodotMethodAttributes,
                                       meth: GodotInstanceMethod)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    nativeScriptRegisterProperty*: proc (gdnativeHandle: pointer,
                                         name, path: cstring,
                                         attr: ptr GodotPropertyAttributes,
                                         setFunc: GodotPropertySetFunc,
                                         getFunc: GodotPropertyGetFunc)
                                        {.noconv, raises: [], gcsafe, tags: [],
                                          .}
    nativeScriptRegisterSignal*: proc (gdnativeHandle: pointer, name: cstring,
                                       signal: GodotSignal)
                                      {.noconv, raises: [], gcsafe, tags: [],
                                        .}
    nativeScriptGetUserdata*: proc (obj: ptr GodotObject): pointer
                                   {.noconv, raises: [], gcsafe, tags: [],
                                     .}

{.push stackTrace: off.}
proc toColor*(val: ColorData): Color {.inline, noinit.} =
  cast[Color](val)

proc toVector3*(val: Vector3Data): Vector3 {.inline, noinit.} =
  cast[Vector3](val)

proc toVector2*(val: Vector2Data): Vector2 {.inline, noinit.} =
  cast[Vector2](val)

proc toPlane*(val: PlaneData): Plane {.inline, noinit.} =
  cast[Plane](val)

proc toBasis*(val: BasisData): Basis {.inline, noinit.} =
  cast[Basis](val)

proc toQuat*(val: QuatData): Quat {.inline, noinit.} =
  cast[Quat](val)

proc toAABB*(val: AABBData): AABB {.inline, noinit.} =
  cast[AABB](val)

proc toRect2*(val: Rect2Data): Rect2 {.inline, noinit.} =
  cast[Rect2](val)

proc toTransform2D*(val: Transform2DData): Transform2D {.inline, noinit.} =
  cast[Transform2D](val)

proc toTransform*(val: TransformData): Transform {.inline, noinit.} =
  cast[Transform](val)
{.pop.}

macro assign(dest, src: typed, values: untyped): typed =
  result = newStmtList()
  for val in values:
    result.add(newNimNode(nnkAsgn).add(
      newNimNode(nnkDotExpr).add(dest, val),
      newNimNode(nnkDotExpr).add(src, val)))

var gdNativeAPI: GDNativeAPI

proc getGDNativeAPI*(): ptr GDNativeAPI {.inline.} =
  addr gdNativeAPI

proc setGDNativeAPIInternal(apiStruct: pointer, initOptions: ptr GDNativeInitOptions,
                            foundCoreApi: var bool, foundNativeScriptApi: var bool) =
  let header = cast[ptr GDNativeAPIHeader](apiStruct)

  if header.typ >= ord(low(GDNativeAPIType)).cuint and header.typ <= ord(high(GDNativeAPIType)).cuint:
    let typ = GDNativeAPIType(header.typ)
    case typ:
    of GDNativeCore:
      let coreApi = cast[ptr GDNativeCoreAPI1](apiStruct)
      if coreApi[].version.major == 1 and coreApi[].version.minor == 0:
        assign(gdNativeApi, coreApi[]):
          # Color API
          colorNewRGBA
          colorNewRGB
          colorGetR
          colorSetR
          colorGetG
          colorSetG
          colorGetB
          colorSetB
          colorGetA
          colorSetA
          colorGetH
          colorGetS
          colorGetV
          colorAsString
          colorToRGBA32
          colorAsARGB32
          colorGray
          colorInverted
          colorContrasted
          colorLinearInterpolate
          colorBlend
          colorToHtml
          colorOperatorEqual
          colorOperatorLess

          # Vector 2 API
          vector2New
          vector2AsString
          vector2Normalized
          vector2Length
          vector2Angle
          vector2LengthSquared
          vector2IsNormalized
          vector2DistanceTo
          vector2DistanceSquaredTo
          vector2AngleTo
          vector2AngleToPoint
          vector2LinearInterpolate
          vector2CubicInterpolate
          vector2Rotated
          vector2Tangent
          vector2Floor
          vector2Snapped
          vector2Aspect
          vector2Dot
          vector2Slide
          vector2Bounce
          vector2Reflect
          vector2Abs
          vector2Clamped
          vector2OperatorAdd
          vector2OperatorSubtract
          vector2OperatorMultiplyVector
          vector2OperatorMultiplyScalar
          vector2OperatorDivideVector
          vector2OperatorDivideScalar
          vector2OperatorEqual
          vector2OperatorLess
          vector2OperatorNeg

          # Quat API
          quatNew
          quatNewWithAxisAngle
          quatGetX
          quatSetX
          quatGetY
          quatSetY
          quatGetZ
          quatSetZ
          quatGetW
          quatSetW
          quatAsString
          quatLength
          quatLengthSquared
          quatNormalized
          quatIsNormalized
          quatInverse
          quatDot
          quatXform
          quatSlerp
          quatSlerpni
          quatCubicSlerp
          quatOperatorMultiply
          quatOperatorAdd
          quatOperatorSubtract
          quatOperatorDivide
          quatOperatorEqual
          quatOperatorNeg

          # PoolByteArray API
          poolByteArrayNew
          poolByteArrayNewCopy
          poolByteArrayNewWithArray
          poolByteArrayAppend
          poolByteArrayAppendArray
          poolByteArrayInsert
          poolByteArrayInvert
          poolByteArrayPushBack
          poolByteArrayRemove
          poolByteArrayResize
          poolByteArrayRead
          poolByteArrayWrite
          poolByteArraySet
          poolByteArrayGet
          poolByteArraySize
          poolByteArrayDestroy

          # PoolIntArray API
          poolIntArrayNew
          poolIntArrayNewCopy
          poolIntArrayNewWithArray
          poolIntArrayAppend
          poolIntArrayAppendArray
          poolIntArrayInsert
          poolIntArrayInvert
          poolIntArrayPushBack
          poolIntArrayRemove
          poolIntArrayResize
          poolIntArrayRead
          poolIntArrayWrite
          poolIntArraySet
          poolIntArrayGet
          poolIntArraySize
          poolIntArrayDestroy

          # PoolRealArray API
          poolRealArrayNew
          poolRealArrayNewCopy
          poolRealArrayNewWithArray
          poolRealArrayAppend
          poolRealArrayAppendArray
          poolRealArrayInsert
          poolRealArrayInvert
          poolRealArrayPushBack
          poolRealArrayRemove
          poolRealArrayResize
          poolRealArrayRead
          poolRealArrayWrite
          poolRealArraySet
          poolRealArrayGet
          poolRealArraySize
          poolRealArrayDestroy

          # PoolStringArray API
          poolStringArrayNew
          poolStringArrayNewCopy
          poolStringArrayNewWithArray
          poolStringArrayAppend
          poolStringArrayAppendArray
          poolStringArrayInsert
          poolStringArrayInvert
          poolStringArrayPushBack
          poolStringArrayRemove
          poolStringArrayResize
          poolStringArrayRead
          poolStringArrayWrite
          poolStringArraySet
          poolStringArrayGet
          poolStringArraySize
          poolStringArrayDestroy


          # PoolVector2 API
          poolVector2ArrayNew
          poolVector2ArrayNewCopy
          poolVector2ArrayNewWithArray
          poolVector2ArrayAppend
          poolVector2ArrayAppendArray
          poolVector2ArrayInsert
          poolVector2ArrayInvert
          poolVector2ArrayPushBack
          poolVector2ArrayRemove
          poolVector2ArrayResize
          poolVector2ArrayRead
          poolVector2ArrayWrite
          poolVector2ArraySet
          poolVector2ArrayGet
          poolVector2ArraySize
          poolVector2ArrayDestroy

          # PoolVector3 API
          poolVector3ArrayNew
          poolVector3ArrayNewCopy
          poolVector3ArrayNewWithArray
          poolVector3ArrayAppend
          poolVector3ArrayAppendArray
          poolVector3ArrayInsert
          poolVector3ArrayInvert
          poolVector3ArrayPushBack
          poolVector3ArrayRemove
          poolVector3ArrayResize
          poolVector3ArrayRead
          poolVector3ArrayWrite
          poolVector3ArraySet
          poolVector3ArrayGet
          poolVector3ArraySize
          poolVector3ArrayDestroy

          # PoolColorArray API
          poolColorArrayNew
          poolColorArrayNewCopy
          poolColorArrayNewWithArray
          poolColorArrayAppend
          poolColorArrayAppendArray
          poolColorArrayInsert
          poolColorArrayInvert
          poolColorArrayPushBack
          poolColorArrayRemove
          poolColorArrayResize
          poolColorArrayRead
          poolColorArrayWrite
          poolColorArraySet
          poolColorArrayGet
          poolColorArraySize
          poolColorArrayDestroy

          # Array API
          arrayNew
          arrayNewCopy
          arrayNewPoolColorArray
          arrayNewPoolVector3Array
          arrayNewPoolVector2Array
          arrayNewPoolStringArray
          arrayNewPoolRealArray
          arrayNewPoolIntArray
          arrayNewPoolByteArray
          arraySet
          arrayGet
          arrayOperatorIndex
          arrayAppend
          arrayClear
          arrayCount
          arrayEmpty
          arrayErase
          arrayFront
          arrayBack
          arrayFind
          arrayFindLast
          arrayHas
          arrayHash
          arrayInsert
          arrayInvert
          arrayPopFront
          arrayPopBack
          arrayPushBack
          arrayPushFront
          arrayRemove
          arrayResize
          arrayRFind
          arraySize
          arraySort
          arraySortCustom
          arrayBSearch
          arrayBSearchCustom
          arrayDestroy

          # Pool Array Read/Write Access API

          poolByteArrayReadAccessCopy
          poolByteArrayReadAccessPtr
          poolByteArrayReadAccessOperatorAssign
          poolByteArrayReadAccessDestroy

          poolIntArrayReadAccessCopy
          poolIntArrayReadAccessPtr
          poolIntArrayReadAccessOperatorAssign
          poolIntArrayReadAccessDestroy

          poolRealArrayReadAccessCopy
          poolRealArrayReadAccessPtr
          poolRealArrayReadAccessOperatorAssign
          poolRealArrayReadAccessDestroy

          poolStringArrayReadAccessCopy
          poolStringArrayReadAccessPtr
          poolStringArrayReadAccessOperatorAssign
          poolStringArrayReadAccessDestroy

          poolVector2ArrayReadAccessCopy
          poolVector2ArrayReadAccessPtr
          poolVector2ArrayReadAccessOperatorAssign
          poolVector2ArrayReadAccessDestroy

          poolVector3ArrayReadAccessCopy
          poolVector3ArrayReadAccessPtr
          poolVector3ArrayReadAccessOperatorAssign
          poolVector3ArrayReadAccessDestroy

          poolColorArrayReadAccessCopy
          poolColorArrayReadAccessPtr
          poolColorArrayReadAccessOperatorAssign
          poolColorArrayReadAccessDestroy

          poolByteArrayWriteAccessCopy
          poolByteArrayWriteAccessPtr
          poolByteArrayWriteAccessOperatorAssign
          poolByteArrayWriteAccessDestroy

          poolIntArrayWriteAccessCopy
          poolIntArrayWriteAccessPtr
          poolIntArrayWriteAccessOperatorAssign
          poolIntArrayWriteAccessDestroy

          poolRealArrayWriteAccessCopy
          poolRealArrayWriteAccessPtr
          poolRealArrayWriteAccessOperatorAssign
          poolRealArrayWriteAccessDestroy

          poolStringArrayWriteAccessCopy
          poolStringArrayWriteAccessPtr
          poolStringArrayWriteAccessOperatorAssign
          poolStringArrayWriteAccessDestroy

          poolVector2ArrayWriteAccessCopy
          poolVector2ArrayWriteAccessPtr
          poolVector2ArrayWriteAccessOperatorAssign
          poolVector2ArrayWriteAccessDestroy

          poolVector3ArrayWriteAccessCopy
          poolVector3ArrayWriteAccessPtr
          poolVector3ArrayWriteAccessOperatorAssign
          poolVector3ArrayWriteAccessDestroy

          poolColorArrayWriteAccessCopy
          poolColorArrayWriteAccessPtr
          poolColorArrayWriteAccessOperatorAssign
          poolColorArrayWriteAccessDestroy

          # Dictionary API
          dictionaryNew
          dictionaryNewCopy
          dictionaryDestroy
          dictionarySize
          dictionaryEmpty
          dictionaryClear
          dictionaryHas
          dictionaryHasAll
          dictionaryErase
          dictionaryHash
          dictionaryKeys
          dictionaryValues
          dictionaryGet
          dictionarySet
          dictionaryOperatorIndex
          dictionaryNext
          dictionaryOperatorEqual
          dictionaryToJson

          # NodePath API
          nodePathNew
          nodePathNewCopy
          nodePathDestroy
          nodePathAsString
          nodePathIsAbsolute
          nodePathGetNameCount
          nodePathGetName
          nodePathGetSubnameCount
          nodePathGetSubname
          nodePathGetConcatenatedSubnames
          nodePathIsEmpty
          nodePathOperatorEqual

          # Plane API
          planeNewWithReals
          planeNewWithVectors
          planeNewWithNormal
          planeAsString
          planeNormalized
          planeCenter
          planeGetAnyPoint
          planeIsPointOver
          planeDistanceTo
          planeHasPoint
          planeProject
          planeIntersect3
          planeIntersectsRay
          planeIntersectsSegment
          planeOperatorNeg
          planeOperatorEqual
          planeSetNormal
          planeGetNormal
          planeGetD
          planeSetD

          # Rect2 API
          rect2NewWithPositionAndSize
          rect2New
          rect2AsString
          rect2GetArea
          rect2Intersects
          rect2Encloses
          rect2HasNoArea
          rect2Clip
          rect2Merge
          rect2HasPoint
          rect2Grow
          rect2Expand
          rect2OperatorEqual
          rect2GetPosition
          rect2GetSize
          rect2SetPosition
          rect2SetSize

          # AABB API
          aabbNew
          aabbGetPosition
          aabbSetPosition
          aabbGetSize
          aabbSetSize
          aabbAsString
          aabbGetArea
          aabbHasNoArea
          aabbHasNoSurface
          aabbIntersects
          aabbEncloses
          aabbMerge
          aabbIntersection
          aabbIntersectsPlane
          aabbIntersectsSegment
          aabbHasPoint
          aabbGetSupport
          aabbGetLongestAxis
          aabbGetLongestAxisIndex
          aabbGetLongestAxisSize
          aabbGetShortestAxis
          aabbGetShortestAxisIndex
          aabbGetShortestAxisSize
          aabbExpand
          aabbGrow
          aabbGetEndpoint
          aabbOperatorEqual

          # RID API
          ridNew
          ridGetID
          ridNewWithResource
          ridOperatorEqual
          ridOperatorLess

          # Transform API
          transformNewWithAxisOrigin
          transformNew
          transformGetBasis
          transformSetBasis
          transformGetOrigin
          transformSetOrigin
          transformAsString
          transformInverse
          transformAffineInverse
          transformOrthonormalized
          transformRotated
          transformScaled
          transformTranslated
          transformLookingAt
          transformXformPlane
          transformXformInvPlane
          transformNewIdentity
          transformOperatorEqual
          transformOperatorMultiply
          transformXformVector3
          transformXformInvVector3
          transformXformAABB
          transformXformInvAABB

          # Transform2D API
          transform2DNew
          transform2DNewAxisOrigin
          transform2DAsString
          transform2DInverse
          transform2DAffineInverse
          transform2DGetRotation
          transform2DGetOrigin
          transform2DGetScale
          transform2DOrthonormalized
          transform2DRotated
          transform2DScaled
          transform2DTranslated
          transform2DXformVector2
          transform2DXformInvVector2
          transform2DBasisXformVector2
          transform2DBasisXformInvVector2
          transform2DInterpolateWith
          transform2DOperatorEqual
          transform2DOperatorMultiply
          transform2DNewIdentity
          transform2DXformRect2
          transform2DXformInvRect2

          # Variant API
          variantGetType
          variantNewCopy
          variantNewNil
          variantNewBool
          variantNewUInt
          variantNewInt
          variantNewReal
          variantNewString
          variantNewVector2
          variantNewRect2
          variantNewVector3
          variantNewTransform2D

          variantNewPlane
          variantNewQuat
          variantNewAABB
          variantNewBasis
          variantNewTransform
          variantNewColor
          variantNewNodePath
          variantNewRID
          variantNewObject
          variantNewDictionary
          variantNewArray
          variantNewPoolByteArray
          variantNewPoolIntArray
          variantNewPoolRealArray
          variantNewPoolStringArray
          variantNewPoolVector2Array
          variantNewPoolVector3Array
          variantNewPoolColorArray
          variantAsBool
          variantAsUInt
          variantAsInt
          variantAsReal
          variantAsString
          variantAsVector2
          variantAsRect2
          variantAsVector3
          variantAsTransform2D
          variantAsPlane
          variantAsQuat
          variantAsAABB
          variantAsBasis
          variantAsTransform
          variantAsColor
          variantAsNodePath
          variantAsRID
          variantAsObject
          variantAsDictionary
          variantAsArray
          variantAsPoolByteArray
          variantAsPoolIntArray
          variantAsPoolRealArray
          variantAsPoolStringArray
          variantAsPoolVector2Array
          variantAsPoolVector3Array
          variantAsPoolColorArray
          variantCall
          variantHasMethod
          variantOperatorEqual
          variantOperatorLess
          variantHashCompare
          variantBooleanize
          variantDestroy

          # String API
          charStringLength
          charStringGetData
          charStringDestroy

          stringNew
          stringNewCopy
          stringWideStr
          stringOperatorEqual
          stringOperatorLess
          stringOperatorPlus
          stringLength
          stringDestroy
          stringUtf8
          stringCharsToUtf8
          stringCharsToUtf8WithLen

          # Misc API
          objectDestroy
          globalGetSingleton
          methodBindGetMethod
          methodBindPtrCall
          methodBindCall
          getClassConstructor

          alloc
          realloc
          free

          printError
          printWarning
          print

        foundCoreApi = true
        for i in 0.cuint..<coreApi.numExtensions:
          setGDNativeAPIInternal(coreApi.extensions[][i.int], initOptions,
                                 foundCoreApi, foundNativeScriptApi)
    of GDNativeExtNativeScript:
      let nativeScriptApi = cast[ptr GDNativeNativeScriptAPI1](apiStruct)
      if nativeScriptApi[].version.major == 1 and
         nativeScriptApi[].version.minor == 0:
        assign(gdNativeApi, nativeScriptApi[]):
          nativeScriptRegisterClass
          nativeScriptRegisterToolClass
          nativeScriptRegisterMethod
          nativeScriptRegisterProperty
          nativeScriptRegisterSignal
          nativeScriptGetUserdata
        foundNativeScriptApi = true

    of GDNativeExtPluginScript, GDNativeExtNativeARVR:
      # Not used
      discard

  if not header.next.isNil and header != header.next:
    setGDNativeAPIInternal(header.next, initOptions,
                           foundCoreApi, foundNativeScriptApi)

proc setGDNativeAPI*(apiStruct: pointer, initOptions: ptr GDNativeInitOptions) =
  var foundCoreApi: bool
  var foundNativeScriptApi: bool

  setGDNativeAPIInternal(apiStruct, initOptions,
                         foundCoreApi, foundNativeScriptApi)

  if not foundCoreApi:
    let want = GDNativeAPIVersion(major: 1, minor: 0)
    initOptions[].reportVersionMismatch(
      initOptions[].gdNativeLibrary, cstring"Core", want,
      GDNativeAPIVersion(major: 0, minor: 0))

  if not foundNativeScriptApi:
    let want = GDNativeAPIVersion(major: 1, minor: 0)
    initOptions[].reportVersionMismatch(
      initOptions[].gdNativeLibrary, cstring"NativeScript",
      want, GDNativeAPIVersion(major: 0, minor: 0))
