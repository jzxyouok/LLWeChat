/*!
 *  \~chinese
 *  @header LLError.h
 *  @abstract SDK定义的错误
 *  @author Hyphenate
 *  @version 3.00
 *
 *  \~english
 *  @header LLError.h
 *  @abstract SDK defined error
 *  @author Hyphenate
 *  @version 3.00
 */

#import <Foundation/Foundation.h>
#import "EMError.h"
#import "LLErrorCode.h"

/*!
 *  \~chinese 
 *  SDK定义的错误
 *
 *  \~english 
 *  SDK defined error
 */
@interface LLError : NSObject

/*!
 *  \~chinese 
 *  错误码
 *
 *  \~english 
 *  Error code
 */
@property (nonatomic) LLErrorCode errorCode;

/*!
 *  \~chinese 
 *  错误描述
 *
 *  \~english 
 *  Error description
 */
@property (nonatomic, copy) NSString *errorDescription;


/*!
 *  \~chinese 
 *  初始化错误实例
 *
 *  @param aDescription  错误描述
 *  @param aCode         错误码
 *
 *  @result 错误实例
 *
 *  \~english
 *  Initialize a error instance
 *
 *  @param aDescription  Error description
 *  @param aCode         Error code
 *
 *  @result Error instance
 */
- (instancetype)initWithDescription:(NSString *)aDescription
                               code:(LLErrorCode)aCode;

/*!
 *  \~chinese 
 *  创建错误实例
 *
 *  @param aDescription  错误描述
 *  @param aCode         错误码
 *
 *  @result 对象实例
 *
 *  \~english
 *  Create a error instance
 *
 *  @param aDescription  Error description
 *  @param aCode         Error code
 *
 *  @result Error instance
 */
+ (instancetype)errorWithDescription:(NSString *)aDescription
                                code:(LLErrorCode)aCode;

+ (instancetype)errorWithEMError:(EMError *)error;

@end
