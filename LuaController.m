//
// LuaController.m
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

#import "LuaController.h"
#import "libluasqlite3.h"


@implementation LuaController

@synthesize state;
@synthesize getResourcePath;

-(void) handleErrors: (int)pCallResult {
	if (!pCallResult) {
		return;
	}
	printf("ERROR (%d): ", pCallResult);
	switch (pCallResult) {
		case LUA_YIELD:
			printf("Yield: ");
			break;
		case LUA_ERRRUN:
			printf("Runtime: ");
			break;
		case LUA_ERRSYNTAX:
			printf("Syntax: ");
			break;
		case LUA_ERRMEM:
			printf("Memory: ");
			break;
		case LUA_ERRERR:
			printf("Error Handing: ");
			break;
		default:
			printf("Unknown: ");
		break;
	}
	printf("%s\n", lua_tostring(state, -1));
	lua_pop(state, 1);
}

-(int) doFile: (NSString *)pFileName {
	NSString *path = self.getResourcePath(pFileName);
	int result = luaL_dofile(state, [path UTF8String]);
	[self handleErrors: result];
	return result;
}

-(int) doString: (NSString *)pString {
	int result = luaL_dostring(state, [pString UTF8String]);
	[self handleErrors: result];
	return result;
}

-(void) pushValueOnStack:(id)pValue forState:(lua_State *)pState atLevel:(int)pLevel {
	lua_checkstack(pState, 1);
	if (LUACONTROLLER_MAX_DEPTH < pLevel) {
		printf("ERROR: Set Value: Recursion error\n");
		lua_pushnil(pState);
	}
	if (Nil == pValue) {
		lua_pushnil(pState);
	} else if ([pValue isKindOfClass:[NSString class]]) {
		lua_pushstring(pState, [pValue UTF8String]);
	} else if ([pValue isKindOfClass:[NSNumber class]]) {
		lua_pushnumber(pState, [pValue floatValue]);
	} else if ([pValue isKindOfClass:[NSDictionary class]]) {
		int tableIndex;
		lua_checkstack(pState, 3);
		lua_newtable(pState);
		tableIndex = lua_gettop(pState);
		for (id key in pValue) {
			[self pushValueOnStack:key forState:pState atLevel:pLevel + 1];
			[self pushValueOnStack:[pValue objectForKey:key] forState:pState atLevel:pLevel + 1];
			lua_settable(pState, tableIndex);
		}
	} else if ([pValue isKindOfClass:[NSArray class]]) {
		int tableIndex;
		int i;
		lua_checkstack(pState, 3);
		lua_createtable(pState, [pValue count], 0);
		tableIndex = lua_gettop(pState);
		for (i = 0; i < [pValue count]; i++) {
			lua_pushinteger(pState, i + 1);
			[self pushValueOnStack:[pValue objectAtIndex:i] forState:pState atLevel:pLevel + 1];
			lua_settable(pState, tableIndex);
		}
	}
}

-(int) setKey:(NSString *)pKey toValue:(id)pValue {
	int result;
	NSString *command = [[NSString alloc]
						 initWithFormat:@"%@ = %@", pKey, LUACONTROLLER_VALUE];
	[self pushValueOnStack:pValue forState:state atLevel:0];
	lua_setglobal(state, [LUACONTROLLER_VALUE UTF8String]);
	result = [self doString:command];
	[command release];
	return result;
}

-(id) getValueFromStack:(int)pStackPosition forState:(lua_State *)pState atLevel:(int)pLevel {
	id result;
	int type = lua_type(pState, pStackPosition);

	if (LUACONTROLLER_MAX_DEPTH < pLevel) {
		printf("ERROR: Get Value: Recursion error\n");
		return Nil;
	}
	switch (type) {
		case LUA_TSTRING:
			result = [NSString stringWithUTF8String: lua_tostring(pState, pStackPosition)];
			break;
		case LUA_TNUMBER:
			result = [NSNumber numberWithFloat: lua_tonumber(pState, pStackPosition)];
			break;
		case LUA_TBOOLEAN:
			if (lua_toboolean(pState, pStackPosition)) {
				result = [NSNumber numberWithInt: lua_toboolean(pState, pStackPosition)];
			} else {
				result = Nil;
			}
			break;
		case LUA_TTABLE: {
			int tableIndex = pStackPosition;
			if (tableIndex < 0) {
				tableIndex += lua_gettop(pState) + 1;
			}
			
			result = [NSMutableDictionary dictionaryWithCapacity:lua_objlen(pState, tableIndex)];
			lua_checkstack(pState, 2);
			lua_pushnil(pState);  /* first key */
			while (lua_next(pState, tableIndex) != 0) {
				id key   = [self getValueFromStack:-2 forState:pState atLevel:pLevel + 1];
				id value = [self getValueFromStack:-1 forState:pState atLevel:pLevel + 1];
				if ((Nil != key) && (Nil != value)) {
					[result setObject:value forKey:key];
				}
				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(pState, 1);
			}
			break;
		}
		case LUA_TFUNCTION:
		case LUA_TUSERDATA:
		case LUA_TTHREAD:
		case LUA_TLIGHTUSERDATA:
			// all of these need wrapper objects
			// fall through
		case LUA_TNIL:
		default:
			result = Nil;
		break;
	}
	return result;
}

-(id) getValueForKey:(NSString *)pKey {
	id  result;
	NSString *command = [[NSString alloc]
						 initWithFormat:@"%@ = %@", LUACONTROLLER_VALUE, pKey];
	[self doString:command];
	lua_checkstack(state, 1);
	lua_getfield(state, LUA_GLOBALSINDEX, [LUACONTROLLER_VALUE UTF8String]);
	result = [self getValueFromStack:-1 forState:state  atLevel:0];
	lua_pop(state, 1);
	[command release];
	return result;
}

-(void) initSqlite3 {
	luaL_Reg systemFunctions[] = {
		{"luaopen_sqlite3", luaopen_sqlite3},
		{NULL, NULL}
	};
	luaL_register(state, "luasql", systemFunctions);
    lua_pop(state, 1);
}

-(LuaController *) init {
	self = [super init];
	state = luaL_newstate();
	luaL_openlibs(state);
	getResourcePath = LuaController_getResourcePath_default;
    [self initSqlite3];
    // [self doFile: @"library.aqd"];
	return self;
}

-(void) dealloc {
	lua_close(state);
    [super dealloc];
}

@end

NSString *LuaController_getResourcePath_default(NSString *pFileName) {
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	return [NSString stringWithFormat: @"%@/%@", bundlePath, pFileName];
}
