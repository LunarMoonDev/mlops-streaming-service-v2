import functools

from toolz import compose
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import FunctionTransformer
from sklearn.feature_extraction import DictVectorizer


def convert_to_dict(df):
    """
    converts dataframe to dict
    """
    return df.to_dict(orient="records")


def preprocessor_with_transform(df, transform: tuple = ()):
    """
    preprocessor pipeline used by model
    """
    return compose(*transform[::-1])(df)


def feature_pipeline(transforms: tuple = ()):
    """
    preprocessor pipeline used by model
    """
    preprocessor = functools.partial(preprocessor_with_transform, transform=transforms)

    return make_pipeline(
        FunctionTransformer(preprocessor),
        FunctionTransformer(convert_to_dict),
        DictVectorizer(),
    )
