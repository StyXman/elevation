local tables = {}

-- Tables don't have to have a geometry column
tables.routes = osm2pgsql.define_way_table('routes', {
    { column = 'tags',   type = 'hstore' },
    { column = 'offset', type = 'float' },
    { column = 'ref',    type = 'text' },
    { column = 'colour', type = 'text' },
    { column = 'way',    type = 'linestring' },
})

-- These tag keys are generally regarded as useless for most rendering. Most
-- of them are from imports or intended as internal information for mappers.
--
-- If a key ends in '*' it will match all keys with the specified prefix.
--
-- If you want some of these keys, perhaps for a debugging layer, just
-- delete the corresponding lines.
local delete_keys = {
    'attribution',
    'comment',
    'created_by',
    'fixme',
    'note',
    'note:*',
    'odbl',
    'odbl:note',
    'source',
    'source:*',
    'source_ref',

    -- Lots of import tags
    -- Corine (CLC) (Europe)
    'CLC:*',

    -- Geobase (CA)
    'geobase:*',
    -- CanVec (CA)
    'canvec:*',

    -- osak (DK)
    'osak:*',
    -- kms (DK)
    'kms:*',

    -- ngbe (ES)
    -- See also note:es and source:file above
    'ngbe:*',

    -- Friuli Venezia Giulia (IT)
    'it:fvg:*',

    -- KSJ2 (JA)
    -- See also note:ja and source_ref above
    'KSJ2:*',
    -- Yahoo/ALPS (JA)
    'yh:*',

    -- LINZ (NZ)
    'LINZ2OSM:*',
    'linz2osm:*',
    'LINZ:*',

    -- WroclawGIS (PL)
    'WroclawGIS:*',
    -- Naptan (UK)
    'naptan:*',

    -- TIGER (US)
    'tiger:*',
    -- GNIS (US)
    'gnis:*',
    -- National Hydrography Dataset (US)
    'NHD:*',
    'nhd:*',
    -- mvdgis (Montevideo, UY)
    'mvdgis:*',

    -- EUROSHA (Various countries)
    'project:eurosha_2012',

    -- UrbIS (Brussels, BE)
    'ref:UrbIS',

    -- NHN (CA)
    'accuracy:meters',
    'sub_sea:type',
    'waterway:type',
    -- StatsCan (CA)
    'statscan:rbuid',

    -- RUIAN (CZ)
    'ref:ruian:addr',
    'ref:ruian',
    'building:ruian:type',
    -- DIBAVOD (CZ)
    'dibavod:id',
    -- UIR-ADR (CZ)
    'uir_adr:ADRESA_KOD',

    -- GST (DK)
    'gst:feat_id',

    -- Maa-amet (EE)
    'maaamet:ETAK',
    -- FANTOIR (FR)
    'ref:FR:FANTOIR',

    -- 3dshapes (NL)
    '3dshapes:ggmodelk',
    -- AND (NL)
    'AND_nosr_r',

    -- OPPDATERIN (NO)
    'OPPDATERIN',
    -- Various imports (PL)
    'addr:city:simc',
    'addr:street:sym_ul',
    'building:usage:pl',
    'building:use:pl',
    -- TERYT (PL)
    'teryt:simc',

    -- RABA (SK)
    'raba:id',
    -- DCGIS (Washington DC, US)
    'dcgis:gis_id',
    -- Building Identification Number (New York, US)
    'nycdoitt:bin',
    -- Chicago Building Inport (US)
    'chicago:building_id',
    -- Louisville, Kentucky/Building Outlines Import (US)
    'lojic:bgnum',
    -- MassGIS (Massachusetts, US)
    'massgis:way_id',

    -- misc
    'import',
    'import_uuid',
    'OBJTYPE',
    'SK53_bulk:load'
}

-- The osm2pgsql.make_clean_tags_func() function takes the list of keys
-- and key prefixes defined above and returns a function that can be used
-- to clean those tags out of a Lua table. The clean_tags function will
-- return true if it removed all tags from the table.
local clean_tags = osm2pgsql.make_clean_tags_func(delete_keys)

-- This will be used to store lists of relation ids queryable by way id
pt_ways = {}
route_in_way = {}

function sort_by_ref(a, b)
    return a.tags.ref < b.tags.ref
end

-- see https://stackoverflow.com/a/27028488/1959016
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function osm2pgsql.process_relation(relation)
    if osm2pgsql.stage == 1 then
        return osm2pgsql.process_relation_stage1(relation)
    else
        return osm2pgsql.process_relation_stage2(relation)
    end

function osm2pgsql.process_way(way)
    -- Do nothing for ways in stage1, it'll be in relations where the magic starts
    if osm2pgsql.stage == 1 then
        return
    end

    return osm2pgsql.process_way_stage2(way)
end

function osm2pgsql.process_relation_stage1(relation)
    -- Only interested in relations with type=route, route=bus and a ref
    -- TODO: other pt routes too
    -- TODO: non-ref routes too
    if relation.tags.type == 'route' and relation.tags.route == 'bus' and relation.tags.ref then
        -- Go through all the members and store relation ids and refs so it
        -- can be found by the way id.
        for _, member in ipairs(relation.members) do
            if member.type == 'w' then  -- ways
                -- print(relation.id, member.ref, relation.tags.ref)
                if not pt_ways[member.ref] then
                    -- this is used as the list, because we can only sort in that case
                    pt_ways[member.ref] = {}
                    -- this is used as a set, to find whether this route was already seen
                    -- in this way
                    route_in_way[member.ref] = {}
                end

                -- deduplicate two directions on the same way
                if not route_in_way[member.ref][relation.tags.ref] then
                    -- insert() is the new append()
                    table.insert(pt_ways[member.ref], relation)
                    route_in_way[member.ref][relation.tags.ref] = true

                    osm2pgsql.mark_way(member.ref)
                end
            end
        end
    end
end

function osm2pgsql.process_way_stage2(way)
    clean_tags(way.tags)

    local routes = pt_ways[way.id]
    table.sort(routes, sort_by_ref)

    local line_width = 2.5
    local offset = 0
    local side = 1
    local base_offset
    local offset
    local index
    local ref
    local slot
    local shift

    if #routes % 2 == 0 then
        base_offset = line_width / 2
        shift = 1
    else
        base_offset = 0
        shift = 0
    end

    for index, route in ipairs(routes) do
        -- index is 1 based!
        slot = math.floor((index - shift) / 2)
        offset = (base_offset + slot * line_width) * side

        -- TODO: group by colour
        -- TODO: generic line if no colour
        row = {
            tags = way.tags,
            ref = route.tags.ref,
            colour = route.tags.colour,
            offset = offset,
            geom = { create = 'line' }
        }

        tables.routes.add_row(tables.routes, row)

        if side == 1 then
            side = -1
        else
            side = 1
        end
    end
end

function osm2pgsql.process_relation_stage2(relation)
end
