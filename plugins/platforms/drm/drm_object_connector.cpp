/********************************************************************
 KWin - the KDE window manager
 This file is part of the KDE project.

Copyright (C) 2016 Roman Gilg <subdiff@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/
#include "drm_object_connector.h"
#include "drm_backend.h"
#include "drm_pointer.h"
#include "logging.h"

namespace KWin
{

DrmConnector::DrmConnector(uint32_t connector_id, DrmBackend *backend)
    : DrmObject(connector_id, backend)
{
    ScopedDrmPointer<_drmModeConnector, &drmModeFreeConnector> con(drmModeGetConnector(backend->fd(), connector_id));
    if (!con) {
        return;
    }
    for (int i = 0; i < con->count_encoders; ++i) {
        m_encoders << con->encoders[i];
    }
}

DrmConnector::~DrmConnector() = default;

bool DrmConnector::atomicInit()
{
    qCDebug(KWIN_DRM) << "Creating connector" << m_id;

    if (!initProps()) {
        return false;
    }
    return true;
}

bool DrmConnector::initProps()
{
    m_propsNames = {
        QByteArrayLiteral("CRTC_ID"),
    };

    drmModeObjectProperties *properties = drmModeObjectGetProperties(m_backend->fd(), m_id, DRM_MODE_OBJECT_CONNECTOR);
    if (!properties) {
        qCWarning(KWIN_DRM) << "Failed to get properties for connector " << m_id ;
        return false;
    }

    int propCount = int(PropertyIndex::Count);
    for (int j = 0; j < propCount; ++j) {
        initProp(j, properties);
    }
    drmModeFreeObjectProperties(properties);
    return true;
}

bool DrmConnector::isConnected()
{
    ScopedDrmPointer<_drmModeConnector, &drmModeFreeConnector> con(drmModeGetConnector(m_backend->fd(), m_id));
    if (!con) {
        return false;
    }
    return con->connection == DRM_MODE_CONNECTED;
}

}
