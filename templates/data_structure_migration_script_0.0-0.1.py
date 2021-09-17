import spinedb_api as api
import sys

url = sys.argv[1]
print("processing " + url)
db_map = api.DatabaseMapping(url)
obj_classes = [
    db_map.cache_to_db("object_class", x._asdict())
    for x in db_map.query(db_map.object_class_sq).filter_by(name="unit_constraint")
]
rel_classes = [
    db_map.cache_to_db("relationship_class", x._asdict())
    for x in db_map.query(db_map.wide_relationship_class_sq).filter(
        db_map.wide_relationship_class_sq.c.name.like("%unit_constraint%")
    )
]
for x in obj_classes + rel_classes:
    x["name"] = x["name"].replace("unit_constraint", "user_constraint")
db_map.update_object_classes(*obj_classes)
db_map.update_wide_relationship_classes(*rel_classes)
db_map.commit_session("Rename unit_constraint to user_constraint")
print("processing complete")
db_map.connection.close()