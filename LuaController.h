//
//  LuaController.h
//  liblua
//
//  Created by Brendan A R Sechter on 10/06/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#define LUACONTROLLER_VALUE		@"_LuaController_value"
#define LUACONTROLLER_MAX_DEPTH	100

@interface LuaController : NSObject {
	lua_State *state;
	NSString *(*getResourcePath)(NSString *pFilename);
}

@property (nonatomic, assign, readonly) lua_State *state;
@property (nonatomic, assign) NSString *(*getResourcePath)(NSString *pFilename);

-(int) doFile: (NSString *)pFileName;
-(int) doString: (NSString *)pString;
-(int) setKey:(NSString *)pKey toValue:(id)pValue;
-(id) getValueForKey:(NSString *)pKey;
-(void) pushValueOnStack:(id)pValue forState:(lua_State *)pState atLevel:(int)pLevel;
-(id) getValueFromStack:(int)pStackPosition forState:(lua_State *)pState atLevel:(int)pLevel;
-(LuaController *) init;
-(void) dealloc;


@end

NSString *LuaController_getResourcePath_default(NSString *pFileName);
