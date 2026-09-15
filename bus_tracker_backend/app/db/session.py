# from sqlalchemy import create_engine
# from sqlalchemy.orm import sessionmaker, declarative_base
# import os
# from dotenv import load_dotenv
# load_dotenv()  # load .env before getenv

# username = os.getenv('POSTGRES_USER')
# password = os.getenv('POSTGRES_PASSWORD')
# host = os.getenv('POSTGRES_HOST')
# port = os.getenv('POSTGRES_PORT', '5432')  # FIXED name
# database = os.getenv('POSTGRES_DB')

# # fail fast if critical envs missing
# missing = [k for k,v in {
#     "POSTGRES_USER": username,
#     "POSTGRES_PASSWORD": password,
#     "POSTGRES_HOST": host,
#     "POSTGRES_DB": database,
# }.items() if not v]
# if missing:
#     raise RuntimeError(f"Missing required DB env vars: {', '.join(missing)}")

# DATABASE_URL = f"postgresql+psycopg2://{username}:{password}@{host}:{port}/{database}"
# engine = create_engine(DATABASE_URL, future=True)
# SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False, future=True)


