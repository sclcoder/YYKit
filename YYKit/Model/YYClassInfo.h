//
//  YYClassInfo.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, YYEncodingType) {
    // 低八位的值： 变量的数据类型 0xFF : 0000 0000 1111 1111
    // 变量类型，因为类型只会有一种，所以就用数字占位
    YYEncodingTypeMask       = 0xFF, ///< mask of type value
    YYEncodingTypeUnknown    = 0, ///< unknown
    // 基础数据类型
    YYEncodingTypeVoid       = 1, ///< void
    YYEncodingTypeBool       = 2, ///< bool
    YYEncodingTypeInt8       = 3, ///< char / BOOL
    YYEncodingTypeUInt8      = 4, ///< unsigned char
    YYEncodingTypeInt16      = 5, ///< short
    YYEncodingTypeUInt16     = 6, ///< unsigned short
    YYEncodingTypeInt32      = 7, ///< int
    YYEncodingTypeUInt32     = 8, ///< unsigned int
    YYEncodingTypeInt64      = 9, ///< long long
    YYEncodingTypeUInt64     = 10, ///< unsigned long long
    YYEncodingTypeFloat      = 11, ///< float
    YYEncodingTypeDouble     = 12, ///< double
    YYEncodingTypeLongDouble = 13, ///< long double
    // 1. 自定义类型 2.NSObject
    YYEncodingTypeObject     = 14, ///< id
    // Class 类型
    YYEncodingTypeClass      = 15, ///< Class
    // SEL字符串
    YYEncodingTypeSEL        = 16, ///< SEL
    YYEncodingTypeBlock      = 17, ///< block
    YYEncodingTypePointer    = 18, ///< void*
    YYEncodingTypeStruct     = 19, ///< struct
    YYEncodingTypeUnion      = 20, ///< union
    // 字符串
    YYEncodingTypeCString    = 21, ///< char*
    // 数组
    YYEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    // 取得8~16位的值类型 ：方法中的参数变量修饰符，理论上只有解析Method的参数才能解析到
    YYEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    YYEncodingTypeQualifierConst  = 1 << 8,  ///< const
    YYEncodingTypeQualifierIn     = 1 << 9,  ///< in
    YYEncodingTypeQualifierInout  = 1 << 10, ///< inout
    YYEncodingTypeQualifierOut    = 1 << 11, ///< out
    YYEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    YYEncodingTypeQualifierByref  = 1 << 13, ///< byref
    YYEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    // 取得16～24位的值类型 ： property修饰符类型
    YYEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    YYEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    YYEncodingTypePropertyCopy         = 1 << 17, ///< copy
    YYEncodingTypePropertyRetain       = 1 << 18, ///< retain
    YYEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    YYEncodingTypePropertyWeak         = 1 << 20, ///< weak
    YYEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    YYEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    YYEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
    
//    这边对于YYEncodingTypeQualifierMask和YYEncodingTypePropertyMask因为存在多种可能的情况，使用了位移(<<)的方式，通过与(&)YYEncodingTypeQualifierMask和YYEncodingTypePropertyMask的方式，判断是否包含某个值
};

/**
 Get the type from a Type-Encoding string.
 
 @discussion See also:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param typeEncoding  A Type-Encoding string.
 @return The encoding type.
 */
YYEncodingType YYEncodingGetType(const char *typeEncoding);


/**
 Instance variable information.
 */

/**  相关知识
 Ivar:An opaque type that represents an instance variable(实例变量，跟某个对象关联，不能被静态方法使用，与之想对应的是class variable).
 
 typedef struct ivar_t *Ivar;
 
 struct ivar_t {
 #if __x86_64__
 // *offset was originally 64-bit on some x86_64 platforms.
 // We read and write only 32 bits of it.
 // Some metadata provides all 64 bits. This is harmless for unsigned
 // little-endian values.
 // Some code uses all 64 bits. class_addIvar() over-allocates the
 // offset for their benefit.
 #endif
 int32_t *offset;
 const char *name;
 const char *type;
 // alignment is sometimes -1; use alignment() instead
 uint32_t alignment_raw;
 uint32_t size;
 
 uint32_t alignment() const {
 if (alignment_raw == ~(uint32_t)0) return 1U << WORD_SHIFT;
 return 1 << alignment_raw;
 }
 };
 
 */

@interface YYClassIvarInfo : NSObject
@property (nonatomic, assign, readonly) Ivar ivar;              ///< ivar opaque struct
@property (nonatomic, strong, readonly) NSString *name;         ///< Ivar's name
@property (nonatomic, assign, readonly) ptrdiff_t offset;       ///< Ivar's offset
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< Ivar's type encoding
@property (nonatomic, assign, readonly) YYEncodingType type;    ///< Ivar's type

 /**  通过断点看 YYClassIvarInfo的信息
 info    YYClassIvarInfo *    0x608000255360    0x0000608000255360
 _ivar    Ivar    0x10aa69ee0    0x000000010aa69ee0
 _name    NSTaggedPointerString *    @"_name"    0xa0000656d616e5f5
 _offset    ptrdiff_t    8
 _typeEncoding    __NSCFString *    @"@\"NSString\""    0x0000608000435680
 _type    YYEncodingType    YYEncodingTypeObject
 
 */


/**
 Creates and returns an ivar info object.
 
 @param ivar ivar opaque struct
 @return A new object, or nil if an error occurs.
 */



- (instancetype)initWithIvar:(Ivar)ivar;
@end


/**
 Method information.
 */
/**
 相关知识
 
 Method:An opaque type that represents a method in a class definition.
 
 typedef struct method_t *Method;
 
 struct method_t {
    SEL name;
    const char *types;
    IMP imp;
 
    struct SortBySELAddress :
        public std::binary_function<const method_t&,const method_t&, bool>
    {
        bool operator() (const method_t& lhs, const method_t& rhs)
        { return lhs.name < rhs.name; }
    };
 };
 
 其中包含两个结构体SEL和IMP：
 
 SEL:An opaque type that represents a method selector
 
 Method selectors are used to represent the name of a method at runtime. A method selector is a C string that has been registered (or “mapped“) with the Objective-C runtime. Selectors generated by the compiler are automatically mapped by the runtime when the class is loaded.

 typedef struct objc_selector *SEL;
 
 
 IMP:A pointer to the function of a method implementation
 
 This data type is a pointer to the start of the function that implements the method. This function uses standard C calling conventions as implemented for the current CPU architecture. The first argument is a pointer to self (that is, the memory for the particular instance of this class, or, for a class method, a pointer to the metaclass). The second argument is the method selector. The method arguments follow.

 
#if !OBJC_OLD_DISPATCH_PROTOTYPES
 typedef void (*IMP)(void  id, SEL, ... );
#else
 typedef id (*IMP)(id, SEL, ...);
 #endif
 
 */


@interface YYClassMethodInfo : NSObject
@property (nonatomic, assign, readonly) Method method; ///< method opaque struct  method指针
@property (nonatomic, strong, readonly) NSString *name; ///< method name          method名
@property (nonatomic, assign, readonly) SEL sel; ///< method's selector
@property (nonatomic, assign, readonly) IMP imp; ///< method's implementation
///< method's parameter and return types     method的参数和返回类型encode types
@property (nonatomic, strong, readonly) NSString *typeEncoding;
 ///< return value's type                    method返回值的encode types
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;
 ///< array of arguments' type               method参数的encode types
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings;
/****
 通过断点看到的YYClassMethodInfo信息
 info    YYClassMethodInfo *    0x60800027bb00    0x000060800027bb00
 _method    Method    0x103546e30    0x0000000103546e30
 _name    NSTaggedPointerString *    @"pages"    0xa000073656761705
 _sel    SEL    "pages"    0x00000001034e7117
 _imp    IMP    (YYKitDemo`-[YYBook pages] at YYModelExample.m:17)    0x00000001033eb8c0
 _typeEncoding    NSTaggedPointerString *    @"Q16@0:8"    0xa383a30403631517
 _returnTypeEncoding    NSTaggedPointerString *    @"Q"    0xa000000000000511
 _argumentTypeEncodings    __NSArrayM *    @"2 elements"    0x0000608000245a30
 [0]    NSTaggedPointerString *    @"@"    0xa000000000000401
 [1]    NSTaggedPointerString *    @":"    0xa0000000000003a1
 
 疑问: 1. 明明pages没有参数，怎么method_getNumberOfArguments解析出来2个参数
 原因就是方法调用最后都会转成((void (*)(id, SEL))objc_msgSend)((id)m, @selector(pages));，所以会有两个参数。
 */

/**
 Creates and returns a method info object.
 
 @param method method opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithMethod:(Method)method;
@end


/**
 Property information.
 */
/** 相关知识
 Property:An opaque type that represents an Objective-C declared property.
 
 typedef struct property_t *objc_property_t;
 
 struct property_t {
    const char *name;
    const char *attributes;
 };

 */
//  对于property来说，本质是:Ivar+getter+setter，所以设置了property也会触发initWithMethod解析

@interface YYClassPropertyInfo : NSObject
//  property指针
@property (nonatomic, assign, readonly) objc_property_t property; ///< property's opaque struct
//  property名
@property (nonatomic, strong, readonly) NSString *name;           ///< property's name
//  property encode解析值
@property (nonatomic, assign, readonly) YYEncodingType type;      ///< property's type
//  property encode string
@property (nonatomic, strong, readonly) NSString *typeEncoding;   ///< property's encoding value
//  property对应的ivar名字
@property (nonatomic, strong, readonly) NSString *ivarName;       ///< property's ivar name
//  property如果是oc类型，oc类型对应的class
@property (nullable, nonatomic, assign, readonly) Class cls;      ///< may be nil
//  property如果存在protocol，protocol列表
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols; ///< may nil
//  property的getter方法
@property (nonatomic, assign, readonly) SEL getter;               ///< getter (nonnull)
//  property的setter方法
@property (nonatomic, assign, readonly) SEL setter;               ///< setter (nonnull)

/*** 通过断点观察 YYClassPropertyInfo 的属性值
 
 info    YYClassPropertyInfo *    0x60400028ea60    0x000060400028ea60
 _property    objc_property_t    0x10e4d1f48    0x000000010e4d1f48
 _name    NSTaggedPointerString *    @"name"    0xa000000656d616e4
 _type    YYEncodingType    655374
 _typeEncoding    __NSCFString *    @"@\"NSString\""    0x0000604000226580
 _ivarName    NSTaggedPointerString *    @"_name"    0xa0000656d616e5f5
 _cls    Class    NSString    0x0000000113082d68
 _protocols    NSArray *    nil    0x0000000000000000
 _getter    SEL    "name"    0x0000000110e6bd17
 _setter    SEL    "setName:"    0x0000000115cc7427
 
 注意： _type的值要转成二进制进行分析  其携带了一个属性的所有信息
 
 */


/**
 Creates and returns a property info object.
 
 @param property property opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end


/**
 Class information for a class.
 */
/**
 相关知识
 
 Class:An opaque type that represents an Objective-C class.
 
 typedef struct objc_class *Class;
 
 struct objc_class : objc_object {
     Class superclass;
     const char *name;
     uint32_t version;
     uint32_t info;
     uint32_t instance_size;
     struct old_ivar_list *ivars;
     struct old_method_list **methodLists;
     Cache cache;
     struct old_protocol_list *protocols;
     // CLS_EXT only
     const uint8_t *ivar_layout;
     struct old_class_ext *ext;
     ...
 }
 
 struct objc_object {
     private:
     isa_t isa;
 
     public:
 
     ...
 }

 */

@interface YYClassInfo : NSObject
//  class指针
@property (nonatomic, assign, readonly) Class cls; ///< class object
//  superClass指针
@property (nullable, nonatomic, assign, readonly) Class superCls; ///< super class object
//  metaClass指针
@property (nullable, nonatomic, assign, readonly) Class metaCls;  ///< class's meta class object
//  是否该class是metaclass
@property (nonatomic, readonly) BOOL isMeta; ///< whether this class is meta class
//  class名
@property (nonatomic, strong, readonly) NSString *name; ///< class name
//  superClass的classinfo（缓存）
@property (nullable, nonatomic, strong, readonly) YYClassInfo *superClassInfo; ///< super class's class info
//  ivar的dictionary,key为ivar的name
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, YYClassIvarInfo *> *ivarInfos; ///< ivars
//  method的dictionary,key为method的name
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, YYClassMethodInfo *> *methodInfos; ///< methods
//  properties的dictionary,key为property的name
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, YYClassPropertyInfo *> *propertyInfos; ///< properties

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.
 
 After called this method, `needUpdate` will returns `YES`, and you should call 
 'classInfoWithClass' or 'classInfoWithClassName' to get the updated class info.
 
 YYClassInfo中有一个needUpdate是否更新的标识符，当手动更改class结构(比如class_addMethod()等)的时候，可以调用方法

 */
- (void)setNeedUpdate;

/**
 If this method returns `YES`, you should stop using this instance and call
 `classInfoWithClass` or `classInfoWithClassName` to get the updated class info.
 
 @return Whether this class info need update.
 */
- (BOOL)needUpdate;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param cls A class.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClass:(Class)cls;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param className A class name.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
