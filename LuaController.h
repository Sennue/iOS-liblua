//
// LuaController.h
// liblua - Glue code to use Lua in iOS projects.
//
// Written in 2010 by Brendan A Sechter <sgeos*splat*hotmail*spot*com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
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
