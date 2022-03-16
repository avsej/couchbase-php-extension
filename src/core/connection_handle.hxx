/**
 * Copyright 2016-Present Couchbase, Inc.
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

#pragma once

#include "core_error_info.hxx"

#include <Zend/zend_API.h>

#include <chrono>
#include <memory>
#include <string>
#include <system_error>

namespace couchbase
{
struct origin;
} // namespace couchbase

namespace couchbase::php
{
class connection_handle
{
  public:
    explicit connection_handle(couchbase::origin origin, std::chrono::steady_clock::time_point idle_expiry);

    [[nodiscard]] zend_resource* resource_id() const
    {
        return id_;
    }

    [[nodiscard]] bool is_expired(std::chrono::steady_clock::time_point now) const
    {
        return idle_expiry_ < now;
    }

    [[nodiscard]] core_error_info open();

  private:
    class impl;

    std::chrono::steady_clock::time_point idle_expiry_; /* time when the connection will be considered as expired */
    zend_resource* id_;

    std::shared_ptr<impl> impl_;
};

std::pair<connection_handle*, core_error_info>
create_connection_handle(const zend_string* connection_string, zval* options, std::chrono::steady_clock::time_point idle_expiry);
} // namespace couchbase::php