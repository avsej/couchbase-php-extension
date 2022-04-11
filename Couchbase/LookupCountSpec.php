<?php

/**
 * Copyright 2014-Present Couchbase, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

declare(strict_types=1);

namespace Couchbase;

/**
 * Indicates to retrieve the count of array items or dictionary keys within a path in a document.
 */
class LookupCountSpec implements LookupInSpec
{
    private string $path;
    private bool $isXattr;

    /**
     * @param string $path
     * @param bool $isXattr
     *
     * @since 4.0.0
     */
    public function __construct(string $path, bool $isXattr = false)
    {
        $this->path = $path;
        $this->isXattr = $isXattr;
    }

    /**
     * @param string $path
     * @param bool $isXattr
     *
     * @return LookupCountSpec
     * @since 4.0.0
     */
    public static function build(string $path, bool $isXattr = false): LookupCountSpec
    {
        return new LookupCountSpec($path, $isXattr);
    }

    /**
     * @internal
     * @return array
     * @since 4.0.0
     */
    public function export(): array
    {
        return [
            'opcode' => 'getCount',
            'isXattr' => $this->isXattr,
            'path' => $this->path,
        ];
    }
}
