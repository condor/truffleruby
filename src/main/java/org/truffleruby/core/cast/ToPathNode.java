/*
 * Copyright (c) 2015, 2017 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0, or
 * GNU General Public License version 2, or
 * GNU Lesser General Public License version 2.1.
 */
package org.truffleruby.core.cast;

import com.oracle.truffle.api.dsl.Cached;
import com.oracle.truffle.api.dsl.NodeChild;
import com.oracle.truffle.api.dsl.Specialization;
import com.oracle.truffle.api.object.DynamicObject;
import org.truffleruby.language.RubyNode;
import org.truffleruby.language.dispatch.CallDispatchHeadNode;

@NodeChild(value = "child", type = RubyNode.class)
public abstract class ToPathNode extends RubyNode {

    @Specialization(guards = "isRubyString(path)")
    public DynamicObject coerceRubyString(DynamicObject path) {
        return path;
    }

    @Specialization(guards = "!isRubyString(object)")
    public DynamicObject coerceObject(Object object,
            @Cached("createOnSelf()") CallDispatchHeadNode toPathNode) {
        return (DynamicObject) toPathNode.call(null, coreLibrary().getTruffleTypeModule(), "coerce_to_path", object);
    }

}
