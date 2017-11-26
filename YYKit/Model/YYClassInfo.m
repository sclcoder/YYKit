//
//  YYClassInfo.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYClassInfo.h"
#import <objc/runtime.h>
/** 这里涉及到typeEncodind的知识 https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    YY这里把typeEncoding 转为自定义的枚举类型，方便管理和使用
*/

// 解析Ivar的type encode string
YYEncodingType YYEncodingGetType(const char *typeEncoding) {

    char *type = (char *)typeEncoding; // "@\"NSString\""
    if (!type) return YYEncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return YYEncodingTypeUnknown;
    
    // 找出修饰语
    YYEncodingType qualifier = 0;
    bool prefix = true;
    /**
     *type操作的作用
     char *type = "type";
     NSLog(@"%s",type);  // type 根据指针获取的是整个字符串
     NSLog(@"%c",*type); // t    获取的是地址的第一个内容
     */
    
    /**
      这里进行 |= 操作的结果
      0000 1111  (十进制的15)
      0000 0011  (十进制的3)
      0000 1111  (15 | 3)
      所以 15 | 3 = 15
     */
    
    // 可能有多个修饰符
    while (prefix) {
        //方法参数Ivar中的解析，理论上解析不到该类参数
        
        // 这里使用 qualifier |= xx 使qualifier获得的xx的值
        // 如果*type满足条件 那么qualifier的8-16位的某些位将会有值 xxxx xxxx 0000 0000
        switch (*type) {
            case 'r': {
                qualifier |= YYEncodingTypeQualifierConst;
                type++;
            } break;
            case 'n': {
                qualifier |= YYEncodingTypeQualifierIn;
                type++;
            } break;
            case 'N': {
                qualifier |= YYEncodingTypeQualifierInout;
                type++;
            } break;
            case 'o': {
                qualifier |= YYEncodingTypeQualifierOut;
                type++;
            } break;
            case 'O': {
                qualifier |= YYEncodingTypeQualifierBycopy;
                type++;
            } break;
            case 'R': {
                qualifier |= YYEncodingTypeQualifierByref;
                type++;
            } break;
            case 'V': {
                qualifier |= YYEncodingTypeQualifierOneway;
                type++;
            } break;
            default: { prefix = false; } break;
        }
    }

    

    len = strlen(type);
    if (len == 0) return YYEncodingTypeUnknown | qualifier;

    switch (*type) {
        // 变量类型，因为类型只会有一种，所以就数字占的位
        case 'v': return YYEncodingTypeVoid | qualifier;
        case 'B': return YYEncodingTypeBool | qualifier;
        case 'c': return YYEncodingTypeInt8 | qualifier;
        case 'C': return YYEncodingTypeUInt8 | qualifier;
        case 's': return YYEncodingTypeInt16 | qualifier;
        case 'S': return YYEncodingTypeUInt16 | qualifier;
        case 'i': return YYEncodingTypeInt32 | qualifier;
        case 'I': return YYEncodingTypeUInt32 | qualifier;
        case 'l': return YYEncodingTypeInt32 | qualifier;
        case 'L': return YYEncodingTypeUInt32 | qualifier;
        case 'q': return YYEncodingTypeInt64 | qualifier;
        case 'Q': return YYEncodingTypeUInt64 | qualifier;
        case 'f': return YYEncodingTypeFloat | qualifier;
        case 'd': return YYEncodingTypeDouble | qualifier;
        case 'D': return YYEncodingTypeLongDouble | qualifier;
        case '#': return YYEncodingTypeClass | qualifier;
        case ':': return YYEncodingTypeSEL | qualifier;
        case '*': return YYEncodingTypeCString | qualifier;
        case '^': return YYEncodingTypePointer | qualifier;
        case '[': return YYEncodingTypeCArray | qualifier;
        case '(': return YYEncodingTypeUnion | qualifier;
        case '{': return YYEncodingTypeStruct | qualifier;
        case '@': {
            if (len == 2 && *(type + 1) == '?')
                return YYEncodingTypeBlock | qualifier;
            else
                // 如果qualifier为0  那么返回值是低8位的值  0000 0000 xxxx xxxx 即会返回本身的值
                return YYEncodingTypeObject | qualifier; // 若qualifier为0 返回14
        }
        default: return YYEncodingTypeUnknown | qualifier;
    }
    
    /**
     该函数也是通过获得的type encode的string，对照着表进行解析，因为是解析Ivar,所以也只包含了YYEncodingTypeMask和YYEncodingTypeQualifierMask。而YYEncodingTypePropertyMask会包含在property的解析中
     */
}

// YYClassIvarInfo本身就是对系统Ivar的一层封装，并进行了一次类型的解析。
@implementation YYClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    if (!ivar) return nil;
    self = [super init];
    _ivar = ivar;
    const char *name = ivar_getName(ivar); // 获取ivar名
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    _offset = ivar_getOffset(ivar); // 成员变量偏移量
    const char *typeEncoding = ivar_getTypeEncoding(ivar); //获取类型encode string
    if (typeEncoding) {
        // 变量类型
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        _type = YYEncodingGetType(typeEncoding); // 类型再次解析
    }
    return self;
}

@end

@implementation YYClassMethodInfo
/**
 SEL:An opaque type that represents a method selector
 
 Method selectors are used to represent the name of a method at runtime. A method selector is a C string that has been registered (or “mapped“) with the Objective-C runtime. Selectors generated by the compiler are automatically mapped by the runtime when the class is loaded.

 
 IMP:A pointer to the function of a method implementation
 
 This data type is a pointer to the start of the function that implements the method. This function uses standard C calling conventions as implemented for the current CPU architecture. The first argument is a pointer to self (that is, the memory for the particular instance of this class, or, for a class method, a pointer to the metaclass). The second argument is the method selector. The method arguments follow.
 
 */

- (instancetype)initWithMethod:(Method)method {
    if (!method) return nil;
    self = [super init];
    _method = method;
    _sel = method_getName(method); // 方法选择器
    _imp = method_getImplementation(method); // 方法实现
    const char *name = sel_getName(_sel); // 方法选择器名称
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    const char *typeEncoding = method_getTypeEncoding(method); //获得方法参数和返回值
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    char *returnType = method_copyReturnType(method); // 获得返回值encode string
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        free(returnType);
    }
    // 方法参数
    unsigned int argumentCount = method_getNumberOfArguments(method);  //获得方法参数数量
    if (argumentCount > 0) {
        NSMutableArray *argumentTypes = [NSMutableArray new];
        for (unsigned int i = 0; i < argumentCount; i++) {  //遍历参数
            char *argumentType = method_copyArgumentType(method, i); //获得该参数的encode string
            NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
            [argumentTypes addObject:type ? type : @""];
            if (argumentType) free(argumentType);
        }
        _argumentTypeEncodings = argumentTypes;
    }
    return self;
}

@end

@implementation YYClassPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property {
    if (!property) return nil;
    self = [super init];
    _property = property;
    const char *name = property_getName(property);   //获得property名
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
    YYEncodingType type = 0;
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        switch (attrs[i].name[0]) {
            case 'T': { // Type encoding    表示是property类型
                if (attrs[i].value) {
                    // 获得attribute的encode string
                    _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                    // 解析type
                    type = YYEncodingGetType(attrs[i].value);
                    
                    // 代表是OC类型
                    if ((type & YYEncodingTypeMask) == YYEncodingTypeObject && _typeEncoding.length) {
                        // 扫描attribute的encode string
                        NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                         // 不包含@\"代表不是oc类型，跳过
                        if (![scanner scanString:@"@\"" intoString:NULL]) continue;
                        
                        NSString *clsName = nil;
                        // 扫描oc类型string，在 \"之前   @\"NSString\"
                        if ([scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                            // 获得oc对象类型，并附值   clsName.UTF8String  c字符串
                            if (clsName.length) _cls = objc_getClass(clsName.UTF8String);
                        }
                        
                        NSMutableArray *protocols = nil;
                         // 扫描<>中的protocol类型，并设置
                        while ([scanner scanString:@"<" intoString:NULL]) {
                            NSString* protocol = nil;
                            if ([scanner scanUpToString:@">" intoString: &protocol]) {
                                if (protocol.length) {
                                    if (!protocols) protocols = [NSMutableArray new];
                                    [protocols addObject:protocol];
                                }
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                        _protocols = protocols;
                    }
                }
            } break;
            case 'V': { // Instance variable    // ivar变量
                if (attrs[i].value) {
                    _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
            case 'R': {     // 以下为property的几种类型扫描,setter和getter方法要记录方法名
                type |= YYEncodingTypePropertyReadonly;
            } break;
            case 'C': {
                type |= YYEncodingTypePropertyCopy;
            } break;
            case '&': {
                type |= YYEncodingTypePropertyRetain;
            } break;
            case 'N': {
                type |= YYEncodingTypePropertyNonatomic;
            } break;
            case 'D': {
                type |= YYEncodingTypePropertyDynamic;
            } break;
            case 'W': {
                type |= YYEncodingTypePropertyWeak;
            } break;
            case 'G': {
                type |= YYEncodingTypePropertyCustomGetter;
                if (attrs[i].value) {
                    _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } break;
            case 'S': {
                type |= YYEncodingTypePropertyCustomSetter;
                if (attrs[i].value) {
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } // break; commented for code coverage in next line
            default: break;
        }
    }
    if (attrs) {   // 有attrs要free
        free(attrs);
        attrs = NULL;
    }
    
    _type = type;  // 最后设置encode解析值   这个值是带有属性信息的组合值
    if (_name.length) { //设置默认的getter方法和setter方法
        if (!_getter) {
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]]);
        }
    }
    return self;
}

@end

@implementation YYClassInfo {
    BOOL _needUpdate;
}
// 初始化class对象方法
- (instancetype)initWithClass:(Class)cls {
    if (!cls) return nil;
    self = [super init];
    _cls = cls;
    //设置superclass
    _superCls = class_getSuperclass(cls);
    //判断是否是metaclass
    _isMeta = class_isMetaClass(cls);
    //不是的话获得meta class
    if (!_isMeta) {
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    //获得类名
    _name = NSStringFromClass(cls);
    //进行更新
    [self _update];
    // 递归superclass
    _superClassInfo = [self.class classInfoWithClass:_superCls];
    
    return self;
}
// 更新函数
- (void)_update {
    //重置ivar，mthod，property3个缓存dictionary
    _ivarInfos = nil;
    _methodInfos = nil;
    _propertyInfos = nil;
    
    Class cls = self.cls;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    //解析method，并以name为key，进行缓存设置
    if (methods) {
        NSMutableDictionary *methodInfos = [NSMutableDictionary new];
        _methodInfos = methodInfos;
        // 遍历方法列表--生成各个方法的信息
        for (unsigned int i = 0; i < methodCount; i++) {
            // 获取类对象方法信息
            YYClassMethodInfo *info = [[YYClassMethodInfo alloc] initWithMethod:methods[i]];
            
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

            // 保存方法信息
            if (info.name) methodInfos[info.name] = info;
        }
        free(methods);
    }
    
    
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    //解析property，并以name为key，进行缓存设置
    if (properties) {
        NSMutableDictionary *propertyInfos = [NSMutableDictionary new];
        _propertyInfos = propertyInfos;
        for (unsigned int i = 0; i < propertyCount; i++) {
            YYClassPropertyInfo *info = [[YYClassPropertyInfo alloc] initWithProperty:properties[i]];
            
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
            
            
            if (info.name) propertyInfos[info.name] = info;
        }
        free(properties);
    }
    
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
     //解析ivar，并以name为key，进行缓存设置
    if (ivars) {
        NSMutableDictionary *ivarInfos = [NSMutableDictionary new];
        _ivarInfos = ivarInfos;
        for (unsigned int i = 0; i < ivarCount; i++) {
            YYClassIvarInfo *info = [[YYClassIvarInfo alloc] initWithIvar:ivars[i]];
            /**  通过断点看 YYClassIvarInfo的信息
             info    YYClassIvarInfo *    0x608000255360    0x0000608000255360
             _ivar    Ivar    0x10aa69ee0    0x000000010aa69ee0
             _name    NSTaggedPointerString *    @"_name"    0xa0000656d616e5f5
             _offset    ptrdiff_t    8
             _typeEncoding    __NSCFString *    @"@\"NSString\""    0x0000608000435680
             _type    YYEncodingType    YYEncodingTypeObject
             
             */
            if (info.name) ivarInfos[info.name] = info;
        }
        free(ivars);
    }
    // 如果不存在相应的方法，则初始化空的dictionary给相应的方法
    if (!_ivarInfos) _ivarInfos = @{};
    if (!_methodInfos) _methodInfos = @{};
    if (!_propertyInfos) _propertyInfos = @{};
    
    // 已经更新完成，设no
    _needUpdate = NO;
    
    // 此方法就是将method,property,ivar全部取出并附值给缓存。
}

- (void)setNeedUpdate {
    _needUpdate = YES;
}

- (BOOL)needUpdate {
    return _needUpdate;
}


/**
 classInfoWithClass方法中主要调用了两个方法- (instancetype)initWithClass:(Class)cls（初始化class）和- (void)_update（更新class
 */
+ (instancetype)classInfoWithClass:(Class)cls {
    if (!cls) return nil;
    //  全局的缓存
     // class缓存
    static CFMutableDictionaryRef classCache;
     // meta class缓存
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
    // 锁  CGD的信号量
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        //初始化两种缓存
    
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
 
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    // 只允许同时1个线程
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    // 获取曾经解析过的缓存
    YYClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        // 如果存在且需要更新，则重新解析class并更新结构体
        // 主要方法1
        [info _update];
    }
     //释放锁
    dispatch_semaphore_signal(lock);
    if (!info) { //如果没有缓存，则第一次解析class
         // 主要方法2
        info = [[YYClassInfo alloc] initWithClass:cls];
        if (info) {
             //解析完毕设置缓存
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}

+ (instancetype)classInfoWithClassName:(NSString *)className {
    Class cls = NSClassFromString(className);
    return [self classInfoWithClass:cls];
}

@end
