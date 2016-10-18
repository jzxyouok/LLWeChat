/*!
 *  \~chinese
 *  @header LLErrorCode.h
 *  @abstract SDK定义的错误类型
 *  @author Hyphenate
 *  @version 3.00
 *
 *  \~english
 *  @header LLErrorCode.h
 *  @abstract SDK defined error type
 *  @author Hyphenate
 *  @version 3.00
 */

typedef enum{

    LLErrorGeneral = 1,                      /*! \~chinese 一般错误 \~english General error */
    LLErrorNetworkUnavailable,               /*! \~chinese 网络不可用 \~english Network is unavaliable */
    
    LLErrorInvalidAppkey = 100,              /*! \~chinese Appkey无效 \~english App key is invalid */
    LLErrorInvalidUsername,                  /*! \~chinese 用户名无效 \~english User name is invalid */
    LLErrorInvalidPassword,                  /*! \~chinese 密码无效 \~english Password is invalid */
    LLErrorInvalidURL,                       /*! \~chinese URL无效 \~english URL is invalid */
    
    LLErrorUserAlreadyLogin = 200,           /*! \~chinese 用户已登录 \~english User has already logged in */
    LLErrorUserNotLogin,                     /*! \~chinese 用户未登录 \~english User has not logged in */
    LLErrorUserAuthenticationFailed,         /*! \~chinese 密码验证失败 \~english Password check failed */
    LLErrorUserAlreadyExist,                 /*! \~chinese 用户已存在 \~english User has already exist */
    LLErrorUserNotFound,                     /*! \~chinese 用户不存在 \~english User was not found */
    LLErrorUserIllegalArgument,              /*! \~chinese 参数不合法 \~english Illegal argument */
    LLErrorUserLoginOnAnotherDevice,         /*! \~chinese 当前用户在另一台设备上登录 \~english User has logged in from another device */
    LLErrorUserRemoved,                      /*! \~chinese 当前用户从服务器端被删掉 \~english User was removed from server */
    LLErrorUserRegisterFailed,               /*! \~chinese 用户注册失败 \~english Register user failed */
    LLErrorUpdateApnsConfigsFailed,          /*! \~chinese 更新推送设置失败 \~english Update apns configs failed */
    LLErrorUserPermissionDenied,             /*! \~chinese 用户没有权限做该操作 \~english User has no right for this operation. */
    
    LLErrorServerNotReachable = 300,         /*! \~chinese 服务器未连接 \~english Server is not reachable */
    LLErrorServerTimeout,                    /*! \~chinese 服务器超时 \~english Wait server response timeout */
    LLErrorServerBusy,                       /*! \~chinese 服务器忙碌 \~english Server is busy */
    LLErrorServerUnknownError,               /*! \~chinese 未知服务器错误 \~english Unknown server error */
    
    LLErrorFileNotFound = 400,               /*! \~chinese 文件没有找到 \~english Can't find the file */
    LLErrorFileInvalid,                      /*! \~chinese 文件无效 \~english File is invalid */
    LLErrorFileUploadFailed,                 /*! \~chinese 上传文件失败 \~english Upload file failed */
    LLErrorFileDownloadFailed,               /*! \~chinese 下载文件失败 \~english Download file failed */
    
    LLErrorMessageInvalid = 500,             /*! \~chinese 消息无效 \~english Message is invalid */
    LLErrorMessageIncludeIllegalContent,      /*! \~chinese 消息内容包含不合法信息 \~english Message contains illegal content */
    LLErrorMessageTrafficLimit,              /*! \~chinese 单位时间发送消息超过上限 \~english Unit time to send messages over the upper limit */
    LLErrorMessageEncryption,                /*! \~chinese 加密错误 \~english Encryption error */
    
    LLErrorGroupInvalidId = 600,             /*! \~chinese 群组ID无效 \~english Group Id is invalid */
    LLErrorGroupAlreadyJoined,               /*! \~chinese 已加入群组 \~english User has already joined the group */
    LLErrorGroupNotJoined,                   /*! \~chinese 未加入群组 \~english User has not joined the group */
    LLErrorGroupPermissionDenied,            /*! \~chinese 没有权限进行该操作 \~english User has NO authority for the operation */
    LLErrorGroupMembersFull,                 /*! \~chinese 群成员个数已达到上限 \~english Reach group's max member count */
    LLErrorGroupNotExist,                    /*! \~chinese 群组不存在 \~english Group is not exist */
    
    LLErrorChatroomInvalidId = 700,          /*! \~chinese 聊天室ID无效 \~english Chatroom id is invalid */
    LLErrorChatroomAlreadyJoined,            /*! \~chinese 已加入聊天室 \~english User has already joined the chatroom */
    LLErrorChatroomNotJoined,                /*! \~chinese 未加入聊天室 \~english User has not joined the chatroom */
    LLErrorChatroomPermissionDenied,         /*! \~chinese 没有权限进行该操作 \~english User has NO authority for the operation */
    LLErrorChatroomMembersFull,              /*! \~chinese 聊天室成员个数达到上限 \~english Reach chatroom's max member count */
    LLErrorChatroomNotExist,                 /*! \~chinese 聊天室不存在 \~english Chatroom is not exist */
    
    LLErrorCallInvalidId = 800,              /*! \~chinese 实时通话ID无效 \~english Call id is invalid */
    LLErrorCallBusy,                         /*! \~chinese 已经在进行实时通话了 \~english User is busy */
    LLErrorCallRemoteOffline,                /*! \~chinese 对方不在线 \~english Callee is offline */
    LLErrorCallConnectFailed,                /*! \~chinese 实时通话建立连接失败 \~english Establish connection failed */

}LLErrorCode;
