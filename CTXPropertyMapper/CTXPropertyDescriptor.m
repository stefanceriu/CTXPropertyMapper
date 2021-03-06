//
//  CTXPropertyDescriptor.m
//  Pods
//
//  Created by Mario on 15/12/2014.
//  Copyright (c) 2015 EF Ltd. All rights reserved.
//

#import "CTXPropertyDescriptor.h"
#import "CTXPropertyMapperErrors.h"

@interface CTXPropertyDescriptor()
@property (nonatomic, strong) NSString *propertyName;
@property (nonatomic, assign) Class propertyClass;
@property (nonatomic, strong) NSMutableArray *validationBlocks;
@property (nonatomic, strong) CTXValueTransformerBlock encodingBlock;
@property (nonatomic, strong) CTXValueTransformerBlock decodingBlock;

@property (nonatomic, assign) enum CTXPropertyDescriptorType type;
@property (nonatomic, assign, readwrite) enum CTXPropertyMapperCodificationMode mode;
@end

@implementation CTXPropertyDescriptor

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithSelector:(SEL)selector
{
    return [self initWithSelector:selector mode:CTXPropertyMapperCodificationModeEncodeAndDecode];
}

- (instancetype)initWithSelector:(SEL)selector mode:(enum CTXPropertyMapperCodificationMode)mode
{
    if (self = [super init]) {
        _propertyName = NSStringFromSelector(selector);
        _type = CTXPropertyDescriptorTypeDirect;
        _mode = mode;
    }
    return self;
}

- (instancetype)initWithSelector:(SEL)selector withClass:(Class)clazz
{
    return [self initWithSelector:selector withClass:clazz mode:CTXPropertyMapperCodificationModeEncodeAndDecode];
}

- (instancetype)initWithSelector:(SEL)selector withClass:(Class)clazz mode:(enum CTXPropertyMapperCodificationMode)mode
{
    if (self = [super init]) {
        _propertyName = NSStringFromSelector(selector);
        _propertyClass = clazz;
        _type = CTXPropertyDescriptorTypeClass;
        _mode = mode;
    }
    return self;
}

- (instancetype)initWithSelector:(SEL)selector encondingBlock:(CTXValueTransformerBlock)encoder decodingBlock:(CTXValueTransformerBlock)decoder
{
    if (self = [super init]) {
        _propertyName = NSStringFromSelector(selector);
        _type = CTXPropertyDescriptorTypeSymmetricalBlock;
        _encodingBlock = encoder;
        _decodingBlock = decoder;
        
        if (encoder) {
            _mode += CTXPropertyMapperCodificationModeEncode;
        }
        
        if (decoder) {
            _mode += CTXPropertyMapperCodificationModeDecode;
        }
        
        if (_mode == 0) {
            NSAssert(YES, @"At least one codification block should be provided!");
        }
    }
    return self;
}

- (instancetype)initWithEncodingGenerationBlock:(CTXValueGenerationBlock)encoder decodingConsumerBlock:(CTXValueConsumerBlock)decoder
{
    if (self = [super init]) {
        _type = CTXPropertyDescriptorTypeAsymmetricalBlock;
        _encodingGenerationBlock = encoder;
        _decodingConsumerBlock = decoder;
        
        if (encoder) {
            _mode += CTXPropertyMapperCodificationModeEncode;
        }
        
        if (decoder) {
            _mode += CTXPropertyMapperCodificationModeDecode;
        }
        
        if (_mode == 0) {
            NSAssert(YES, @"At least one codification block should be provided!");
        }
    }
    return self;
}

- (void)addValidationWithBlock:(NSError * (^)(NSString *name, NSString *))validationBlock
{
    if (!self.validationBlocks) {
        self.validationBlocks = [NSMutableArray new];
    }
    
    [self.validationBlocks addObject:validationBlock];
}

- (void)addValidatorWithName:(NSString *)name validation:(BOOL (^)(id value))validator
{
    [self addValidationWithBlock:^NSError *(NSString *value, NSString *propertyName) {
        BOOL validationResult = validator(value);
        if ([value isKindOfClass:NSNull.class] || !value || !validationResult) {
            NSString *description = [NSString stringWithFormat:CTXPropertyMapperErrorDescription(CTXPropertyMapperErrorCodeValidationFailed), name, propertyName];

            NSError *error = [NSError errorWithDomain:kCTXPropertyMapperErrorDomain
                                                 code:CTXPropertyMapperErrorCodeValidationFailed
                                             userInfo:@{NSLocalizedDescriptionKey : description}];

            return error;
        }
        return nil;
    }];
}

- (NSArray *)validateValue:(id)value
{
    NSMutableArray *errors = [NSMutableArray new];
    [self.validationBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSError *(^validationBlock)(id, NSString *) = obj;
        NSError *error = validationBlock(value, self.propertyName);
        if (error) {
            [errors addObject:error];
        }
    }];
    return errors;
}
@end
